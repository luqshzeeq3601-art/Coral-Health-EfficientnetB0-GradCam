# React Native Performance Optimization

## Table of Contents
1. [Startup Time](#startup-time)
2. [Rendering Performance](#rendering-performance)
3. [Memory Management](#memory-management)
4. [Bundle Size](#bundle-size)
5. [Network Optimization](#network-optimization)
6. [Battery Efficiency](#battery-efficiency)
7. [Profiling Tools](#profiling-tools)

---

## Startup Time

### Target: < 2 seconds cold start

### Enable Hermes Engine
```json
// android/app/build.gradle
project.ext.react = [
    enableHermes: true
]

// iOS: Already enabled by default in RN 0.70+
```

### Lazy Load Screens
```tsx
import { lazy, Suspense } from 'react';

const SettingsScreen = lazy(() => import('./screens/SettingsScreen'));

function App() {
  return (
    <Suspense fallback={<LoadingScreen />}>
      <SettingsScreen />
    </Suspense>
  );
}
```

### Defer Non-Critical Work
```tsx
import { InteractionManager } from 'react-native';

useEffect(() => {
  InteractionManager.runAfterInteractions(() => {
    // Heavy work after animations complete
    loadAnalytics();
    prefetchData();
  });
}, []);
```

### Optimize Imports
```tsx
// Bad: Imports entire library
import { Button, Card, Text } from 'react-native-paper';

// Good: Tree-shakeable (if supported)
import Button from 'react-native-paper/lib/module/components/Button';
```

---

## Rendering Performance

### Target: 60fps (16ms per frame)

### Avoid Re-renders

```tsx
// 1. Use React.memo for pure components
export const ProductCard = memo(function ProductCard({ product }: Props) {
  return <View>...</View>;
});

// 2. Memoize callbacks
const handlePress = useCallback(() => {
  navigation.navigate('Detail', { id: item.id });
}, [item.id, navigation]);

// 3. Memoize expensive calculations
const sortedItems = useMemo(() => {
  return items.sort((a, b) => b.price - a.price);
}, [items]);

// 4. Selective Zustand subscriptions
const userName = useUserStore((state) => state.name); // Only re-renders on name change
```

### Optimize Lists

```tsx
import { FlashList } from '@shopify/flash-list';

// FlashList is 5-10x faster than FlatList
<FlashList
  data={products}
  renderItem={renderProduct}
  estimatedItemSize={120}
  // Optimize based on content
  getItemType={(item) => item.type}
  // Reduce memory for offscreen items
  drawDistance={250}
/>

// For FlatList, use these optimizations:
<FlatList
  data={items}
  renderItem={renderItem}
  keyExtractor={(item) => item.id}
  removeClippedSubviews={true}
  maxToRenderPerBatch={10}
  updateCellsBatchingPeriod={50}
  windowSize={5}
  getItemLayout={(data, index) => ({
    length: ITEM_HEIGHT,
    offset: ITEM_HEIGHT * index,
    index,
  })}
/>
```

### Avoid Inline Functions & Styles
```tsx
// Bad
<Pressable onPress={() => handlePress(item.id)} style={{ padding: 16 }}>

// Good
const styles = StyleSheet.create({ container: { padding: 16 } });
const handleItemPress = useCallback(() => handlePress(item.id), [item.id]);
<Pressable onPress={handleItemPress} style={styles.container}>
```

### Use RepaintBoundary for Complex UI
```tsx
import { View } from 'react-native';

// Wrap complex animations to isolate repaints
<View renderToHardwareTextureAndroid collapsable={false}>
  <ComplexAnimation />
</View>
```

---

## Memory Management

### Target: < 150MB baseline, no leaks

### Clean Up Effects
```tsx
useEffect(() => {
  const subscription = eventEmitter.addListener('event', handler);

  return () => {
    subscription.remove(); // Always clean up
  };
}, []);
```

### Optimize Images
```tsx
// Use expo-image or react-native-fast-image
import { Image } from 'expo-image';

<Image
  source={{ uri: imageUrl }}
  placeholder={blurhash}
  contentFit="cover"
  transition={200}
  cachePolicy="memory-disk"
/>

// Resize images on the fly
const optimizedUrl = `${imageUrl}?w=400&h=400&fit=crop`;
```

### Avoid Memory Leaks in Navigation
```tsx
// Use useFocusEffect instead of useEffect for screen-specific logic
import { useFocusEffect } from '@react-navigation/native';

useFocusEffect(
  useCallback(() => {
    const subscription = subscribe();
    return () => subscription.unsubscribe();
  }, [])
);
```

### Pagination for Large Data
```tsx
const { data, fetchNextPage, hasNextPage } = useInfiniteQuery({
  queryKey: ['products'],
  queryFn: ({ pageParam = 0 }) => fetchProducts(pageParam),
  getNextPageParam: (lastPage) => lastPage.nextCursor,
});

<FlashList
  data={data.pages.flat()}
  onEndReached={() => hasNextPage && fetchNextPage()}
  onEndReachedThreshold={0.5}
/>
```

---

## Bundle Size

### Target: < 50MB APK, < 30MB IPA

### Analyze Bundle
```bash
# React Native
npx react-native-bundle-visualizer

# Expo
npx expo export --dump-sourcemap
npx source-map-explorer dist/bundle.js
```

### Code Splitting
```tsx
// Dynamic imports for large features
const AdminPanel = lazy(() => import('./features/admin/AdminPanel'));
const ReportGenerator = lazy(() => import('./features/reports/ReportGenerator'));
```

### Optimize Assets
```bash
# Compress images
npx expo-optimize

# Use WebP format (smaller than PNG/JPG)
# Convert at build time or use CDN transformation
```

### Remove Unused Dependencies
```bash
# Find unused packages
npx depcheck

# Use lighter alternatives
# moment.js (67KB) → date-fns (13KB) or dayjs (2KB)
# lodash (72KB) → lodash-es with tree-shaking
```

### ProGuard for Android
```groovy
// android/app/build.gradle
def enableProguardInReleaseBuilds = true
```

---

## Network Optimization

### Cache API Responses
```tsx
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 5 * 60 * 1000, // 5 minutes
      gcTime: 30 * 60 * 1000, // 30 minutes cache
      retry: 2,
    },
  },
});
```

### Prefetch Data
```tsx
// Prefetch on hover/focus
const prefetchProduct = (id: string) => {
  queryClient.prefetchQuery({
    queryKey: ['product', id],
    queryFn: () => fetchProduct(id),
  });
};

<Pressable
  onPressIn={() => prefetchProduct(item.id)}
  onPress={() => navigate('Product', { id: item.id })}
>
```

### Optimize API Calls
```tsx
// 1. Request only needed fields (GraphQL or sparse fieldsets)
const { data } = await api.get('/products?fields=id,name,price,thumbnail');

// 2. Batch requests
const products = await Promise.all(ids.map(fetchProduct));

// 3. Use compression
axios.defaults.headers['Accept-Encoding'] = 'gzip';
```

### Offline Support
```tsx
import NetInfo from '@react-native-community/netinfo';
import { onlineManager } from '@tanstack/react-query';

// Pause queries when offline
onlineManager.setEventListener((setOnline) => {
  return NetInfo.addEventListener((state) => {
    setOnline(!!state.isConnected);
  });
});
```

---

## Battery Efficiency

### Reduce Background Work
```tsx
import { AppState } from 'react-native';

useEffect(() => {
  const subscription = AppState.addEventListener('change', (state) => {
    if (state === 'background') {
      pauseAnimations();
      stopPolling();
    } else if (state === 'active') {
      resumeAnimations();
      startPolling();
    }
  });
  return () => subscription.remove();
}, []);
```

### Optimize Location Tracking
```tsx
import * as Location from 'expo-location';

// Use significant changes instead of continuous tracking
await Location.startLocationUpdatesAsync('location-task', {
  accuracy: Location.Accuracy.Balanced, // Not Highest
  distanceInterval: 100, // Meters
  deferredUpdatesInterval: 60000, // 1 minute
});
```

### Batch Analytics
```tsx
// Don't send every event immediately
const analyticsQueue: Event[] = [];

const trackEvent = (event: Event) => {
  analyticsQueue.push(event);
  if (analyticsQueue.length >= 10) {
    flushAnalytics();
  }
};
```

---

## Profiling Tools

### React DevTools
```bash
npx react-devtools
```
- Highlight re-renders
- Profile component performance
- Inspect props and state

### Flipper
```bash
# Already integrated in React Native
# Open Flipper desktop app
```
- Network inspector
- Layout inspector
- React DevTools integration
- Performance profiler

### Android Studio Profiler
- CPU profiling
- Memory allocation
- Network monitoring
- Energy profiler

### Xcode Instruments
- Time Profiler
- Allocations
- Leaks
- Core Animation FPS

### Performance Monitoring
```tsx
// Use performance.now() for custom metrics
const startTime = performance.now();
await heavyOperation();
const duration = performance.now() - startTime;
console.log(`Operation took ${duration}ms`);

// React Native Performance API (New Architecture)
import { PerformanceObserver } from 'react-native';
```

---

## Performance Checklist

### Before Release
- [ ] Enable Hermes
- [ ] Enable ProGuard (Android)
- [ ] Analyze and reduce bundle size
- [ ] Test on low-end devices
- [ ] Profile memory for leaks
- [ ] Check 60fps in animations
- [ ] Verify startup time < 2s
- [ ] Test offline functionality

### Code Review
- [ ] No inline functions in render
- [ ] No inline styles in render
- [ ] Lists use FlashList or optimized FlatList
- [ ] Heavy components are memoized
- [ ] Effects have cleanup functions
- [ ] Images are properly sized and cached
