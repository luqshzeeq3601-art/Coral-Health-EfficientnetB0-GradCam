# React Native Component Patterns & Architecture

## Table of Contents
1. [Component Patterns](#component-patterns)
2. [Animation Patterns](#animation-patterns)
3. [Navigation Patterns](#navigation-patterns)
4. [Form Patterns](#form-patterns)
5. [State Patterns](#state-patterns)
6. [Testing Patterns](#testing-patterns)

---

## Component Patterns

### Compound Components
```tsx
// Usage: <Card><Card.Header /><Card.Body /></Card>
interface CardContextType {
  variant: 'elevated' | 'outlined';
}

const CardContext = createContext<CardContextType | null>(null);

function Card({ variant = 'elevated', children }: CardProps) {
  return (
    <CardContext.Provider value={{ variant }}>
      <View className={variant === 'elevated' ? 'bg-white shadow-md' : 'border border-gray-200'}>
        {children}
      </View>
    </CardContext.Provider>
  );
}

Card.Header = function CardHeader({ children }: { children: ReactNode }) {
  return <View className="p-4 border-b border-gray-100">{children}</View>;
};

Card.Body = function CardBody({ children }: { children: ReactNode }) {
  return <View className="p-4">{children}</View>;
};

Card.Footer = function CardFooter({ children }: { children: ReactNode }) {
  return <View className="p-4 border-t border-gray-100 flex-row justify-end">{children}</View>;
};

export { Card };
```

### Polymorphic Components
```tsx
type AsProp<C extends ElementType> = { as?: C };
type PropsToOmit<C extends ElementType, P> = keyof (AsProp<C> & P);
type PolymorphicProps<C extends ElementType, Props = {}> =
  Props & AsProp<C> & Omit<ComponentPropsWithoutRef<C>, PropsToOmit<C, Props>>;

function Typography<C extends ElementType = typeof Text>({
  as,
  variant = 'body',
  children,
  ...props
}: PolymorphicProps<C, { variant?: 'h1' | 'h2' | 'body' | 'caption' }>) {
  const Component = as || Text;
  const styles = {
    h1: 'text-3xl font-bold',
    h2: 'text-2xl font-semibold',
    body: 'text-base',
    caption: 'text-sm text-gray-500',
  };

  return (
    <Component className={styles[variant]} {...props}>
      {children}
    </Component>
  );
}
```

### Pressable with Feedback
```tsx
import Animated, { useAnimatedStyle, useSharedValue, withSpring } from 'react-native-reanimated';

const AnimatedPressable = Animated.createAnimatedComponent(Pressable);

interface TouchableScaleProps extends PressableProps {
  scale?: number;
  children: ReactNode;
}

export function TouchableScale({ scale = 0.95, children, ...props }: TouchableScaleProps) {
  const scaleValue = useSharedValue(1);

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scaleValue.value }],
  }));

  return (
    <AnimatedPressable
      style={animatedStyle}
      onPressIn={() => { scaleValue.value = withSpring(scale); }}
      onPressOut={() => { scaleValue.value = withSpring(1); }}
      {...props}
    >
      {children}
    </AnimatedPressable>
  );
}
```

### Skeleton Loading
```tsx
import Animated, { useAnimatedStyle, withRepeat, withTiming } from 'react-native-reanimated';
import { LinearGradient } from 'expo-linear-gradient';

export function Skeleton({ width, height, borderRadius = 8 }: SkeletonProps) {
  const translateX = useSharedValue(-width);

  useEffect(() => {
    translateX.value = withRepeat(
      withTiming(width, { duration: 1000 }),
      -1,
      false
    );
  }, []);

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ translateX: translateX.value }],
  }));

  return (
    <View style={{ width, height, borderRadius, backgroundColor: '#e0e0e0', overflow: 'hidden' }}>
      <Animated.View style={[{ width, height }, animatedStyle]}>
        <LinearGradient
          colors={['transparent', 'rgba(255,255,255,0.5)', 'transparent']}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 0 }}
          style={{ width, height }}
        />
      </Animated.View>
    </View>
  );
}
```

---

## Animation Patterns

### Enter/Exit Animations
```tsx
import Animated, { FadeIn, FadeOut, SlideInRight, SlideOutLeft, Layout } from 'react-native-reanimated';

// Fade in on mount
<Animated.View entering={FadeIn.duration(300)}>
  <Content />
</Animated.View>

// Slide transitions
<Animated.View
  entering={SlideInRight.springify()}
  exiting={SlideOutLeft}
>
  <Card />
</Animated.View>

// Layout animations for list changes
<Animated.View layout={Layout.springify()}>
  {items.map(item => <Item key={item.id} />)}
</Animated.View>
```

### Scroll-Based Animations
```tsx
import Animated, { useAnimatedScrollHandler, useAnimatedStyle, interpolate } from 'react-native-reanimated';

function ParallaxScrollView() {
  const scrollY = useSharedValue(0);

  const scrollHandler = useAnimatedScrollHandler({
    onScroll: (event) => {
      scrollY.value = event.contentOffset.y;
    },
  });

  const headerStyle = useAnimatedStyle(() => ({
    transform: [
      { translateY: interpolate(scrollY.value, [0, 200], [0, -100], 'clamp') },
      { scale: interpolate(scrollY.value, [-100, 0], [1.5, 1], 'clamp') },
    ],
    opacity: interpolate(scrollY.value, [0, 150], [1, 0]),
  }));

  return (
    <Animated.ScrollView onScroll={scrollHandler} scrollEventThrottle={16}>
      <Animated.Image source={headerImage} style={[styles.header, headerStyle]} />
      <Content />
    </Animated.ScrollView>
  );
}
```

### Gesture-Based Animations
```tsx
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import Animated, { useSharedValue, useAnimatedStyle, withSpring } from 'react-native-reanimated';

function SwipeableCard() {
  const translateX = useSharedValue(0);
  const context = useSharedValue({ x: 0 });

  const panGesture = Gesture.Pan()
    .onStart(() => {
      context.value = { x: translateX.value };
    })
    .onUpdate((event) => {
      translateX.value = context.value.x + event.translationX;
    })
    .onEnd((event) => {
      if (Math.abs(event.velocityX) > 500 || Math.abs(translateX.value) > 150) {
        // Swipe away
        translateX.value = withSpring(event.velocityX > 0 ? 500 : -500);
      } else {
        // Snap back
        translateX.value = withSpring(0);
      }
    });

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ translateX: translateX.value }],
  }));

  return (
    <GestureDetector gesture={panGesture}>
      <Animated.View style={animatedStyle}>
        <CardContent />
      </Animated.View>
    </GestureDetector>
  );
}
```

### Shared Element Transitions
```tsx
import { SharedTransition, withSpring } from 'react-native-reanimated';

const customTransition = SharedTransition.custom((values) => {
  'worklet';
  return {
    originX: withSpring(values.targetOriginX),
    originY: withSpring(values.targetOriginY),
    width: withSpring(values.targetWidth),
    height: withSpring(values.targetHeight),
  };
});

// In list screen
<Animated.Image
  sharedTransitionTag={`image-${item.id}`}
  sharedTransitionStyle={customTransition}
  source={{ uri: item.image }}
/>

// In detail screen
<Animated.Image
  sharedTransitionTag={`image-${id}`}
  sharedTransitionStyle={customTransition}
  source={{ uri: image }}
/>
```

---

## Navigation Patterns

### Type-Safe Navigation
```tsx
// types/navigation.ts
type RootStackParamList = {
  Home: undefined;
  ProductList: { categoryId: string };
  ProductDetail: { productId: string };
  Cart: undefined;
  Checkout: { couponCode?: string };
};

type TabParamList = {
  Home: undefined;
  Search: undefined;
  Cart: undefined;
  Profile: undefined;
};

// hooks/useTypedNavigation.ts
import { useNavigation } from '@react-navigation/native';
import { NativeStackNavigationProp } from '@react-navigation/native-stack';

export function useAppNavigation() {
  return useNavigation<NativeStackNavigationProp<RootStackParamList>>();
}

// Usage
const navigation = useAppNavigation();
navigation.navigate('ProductDetail', { productId: '123' }); // Type-checked!
```

### Deep Linking
```tsx
const linking = {
  prefixes: ['myapp://', 'https://myapp.com'],
  config: {
    screens: {
      Home: '',
      ProductDetail: 'product/:productId',
      Cart: 'cart',
      Checkout: 'checkout',
    },
  },
};

<NavigationContainer linking={linking}>
  <RootNavigator />
</NavigationContainer>
```

### Auth Flow
```tsx
function RootNavigator() {
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated);
  const isLoading = useAuthStore((s) => s.isLoading);

  if (isLoading) {
    return <SplashScreen />;
  }

  return (
    <Stack.Navigator screenOptions={{ headerShown: false }}>
      {isAuthenticated ? (
        <Stack.Screen name="Main" component={MainNavigator} />
      ) : (
        <Stack.Screen name="Auth" component={AuthNavigator} />
      )}
    </Stack.Navigator>
  );
}
```

### Bottom Sheet Navigation
```tsx
import { BottomSheetModal, BottomSheetModalProvider } from '@gorhom/bottom-sheet';

function ProductScreen() {
  const bottomSheetRef = useRef<BottomSheetModal>(null);
  const snapPoints = useMemo(() => ['25%', '50%', '90%'], []);

  return (
    <BottomSheetModalProvider>
      <View className="flex-1">
        <ProductContent />
        <Button onPress={() => bottomSheetRef.current?.present()}>
          Show Options
        </Button>

        <BottomSheetModal
          ref={bottomSheetRef}
          snapPoints={snapPoints}
          backdropComponent={BottomSheetBackdrop}
        >
          <BottomSheetView>
            <OptionsContent />
          </BottomSheetView>
        </BottomSheetModal>
      </View>
    </BottomSheetModalProvider>
  );
}
```

---

## Form Patterns

### React Hook Form Integration
```tsx
import { useForm, Controller } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';

const loginSchema = z.object({
  email: z.string().email('Invalid email'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
});

type LoginForm = z.infer<typeof loginSchema>;

function LoginScreen() {
  const { control, handleSubmit, formState: { errors } } = useForm<LoginForm>({
    resolver: zodResolver(loginSchema),
  });

  const onSubmit = (data: LoginForm) => {
    login(data);
  };

  return (
    <View className="flex-1 p-4">
      <Controller
        control={control}
        name="email"
        render={({ field: { onChange, onBlur, value } }) => (
          <TextInput
            placeholder="Email"
            onBlur={onBlur}
            onChangeText={onChange}
            value={value}
            keyboardType="email-address"
            autoCapitalize="none"
            className={`border rounded-xl p-4 ${errors.email ? 'border-red-500' : 'border-gray-300'}`}
          />
        )}
      />
      {errors.email && <Text className="text-red-500 mt-1">{errors.email.message}</Text>}

      <Controller
        control={control}
        name="password"
        render={({ field: { onChange, onBlur, value } }) => (
          <TextInput
            placeholder="Password"
            onBlur={onBlur}
            onChangeText={onChange}
            value={value}
            secureTextEntry
            className={`border rounded-xl p-4 mt-4 ${errors.password ? 'border-red-500' : 'border-gray-300'}`}
          />
        )}
      />
      {errors.password && <Text className="text-red-500 mt-1">{errors.password.message}</Text>}

      <Button onPress={handleSubmit(onSubmit)} className="mt-6">
        Login
      </Button>
    </View>
  );
}
```

### Keyboard Handling
```tsx
import { KeyboardAvoidingView, Platform } from 'react-native';
import { KeyboardAwareScrollView } from 'react-native-keyboard-aware-scroll-view';

// Simple forms
<KeyboardAvoidingView
  behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
  className="flex-1"
>
  <FormContent />
</KeyboardAvoidingView>

// Complex forms with scroll
<KeyboardAwareScrollView
  enableOnAndroid
  extraScrollHeight={20}
  keyboardShouldPersistTaps="handled"
>
  <LongFormContent />
</KeyboardAwareScrollView>
```

---

## State Patterns

### Zustand with Persist & Immer
```tsx
import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import { immer } from 'zustand/middleware/immer';
import AsyncStorage from '@react-native-async-storage/async-storage';

interface CartStore {
  items: CartItem[];
  addItem: (product: Product) => void;
  removeItem: (id: string) => void;
  updateQuantity: (id: string, quantity: number) => void;
  clear: () => void;
}

export const useCartStore = create<CartStore>()(
  persist(
    immer((set) => ({
      items: [],
      addItem: (product) =>
        set((state) => {
          const existing = state.items.find((i) => i.id === product.id);
          if (existing) {
            existing.quantity += 1;
          } else {
            state.items.push({ ...product, quantity: 1 });
          }
        }),
      removeItem: (id) =>
        set((state) => {
          state.items = state.items.filter((i) => i.id !== id);
        }),
      updateQuantity: (id, quantity) =>
        set((state) => {
          const item = state.items.find((i) => i.id === id);
          if (item) item.quantity = quantity;
        }),
      clear: () => set({ items: [] }),
    })),
    {
      name: 'cart-storage',
      storage: createJSONStorage(() => AsyncStorage),
    }
  )
);
```

### TanStack Query Patterns
```tsx
// hooks/useProducts.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';

export function useProducts(categoryId?: string) {
  return useQuery({
    queryKey: ['products', categoryId],
    queryFn: () => fetchProducts(categoryId),
    staleTime: 5 * 60 * 1000, // 5 minutes
  });
}

export function useProduct(id: string) {
  return useQuery({
    queryKey: ['product', id],
    queryFn: () => fetchProduct(id),
    enabled: !!id,
  });
}

export function useCreateProduct() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: createProduct,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['products'] });
    },
    onMutate: async (newProduct) => {
      // Optimistic update
      await queryClient.cancelQueries({ queryKey: ['products'] });
      const previous = queryClient.getQueryData(['products']);
      queryClient.setQueryData(['products'], (old: Product[]) => [...old, newProduct]);
      return { previous };
    },
    onError: (err, newProduct, context) => {
      queryClient.setQueryData(['products'], context?.previous);
    },
  });
}
```

---

## Testing Patterns

### Component Testing
```tsx
import { render, screen, fireEvent } from '@testing-library/react-native';

describe('ProductCard', () => {
  it('renders product information', () => {
    const product = { id: '1', name: 'Test Product', price: 99.99 };
    render(<ProductCard product={product} />);

    expect(screen.getByText('Test Product')).toBeTruthy();
    expect(screen.getByText('$99.99')).toBeTruthy();
  });

  it('calls onPress when tapped', () => {
    const onPress = jest.fn();
    const product = { id: '1', name: 'Test', price: 10 };
    render(<ProductCard product={product} onPress={onPress} />);

    fireEvent.press(screen.getByRole('button'));
    expect(onPress).toHaveBeenCalledWith('1');
  });
});
```

### Hook Testing
```tsx
import { renderHook, act } from '@testing-library/react-native';
import { useCartStore } from './useCartStore';

describe('useCartStore', () => {
  beforeEach(() => {
    useCartStore.setState({ items: [] });
  });

  it('adds item to cart', () => {
    const { result } = renderHook(() => useCartStore());
    const product = { id: '1', name: 'Test', price: 10 };

    act(() => {
      result.current.addItem(product);
    });

    expect(result.current.items).toHaveLength(1);
    expect(result.current.items[0].quantity).toBe(1);
  });
});
```

### E2E Testing with Detox
```tsx
// e2e/login.test.ts
describe('Login Flow', () => {
  beforeAll(async () => {
    await device.launchApp();
  });

  it('should login successfully', async () => {
    await element(by.id('email-input')).typeText('test@example.com');
    await element(by.id('password-input')).typeText('password123');
    await element(by.id('login-button')).tap();

    await expect(element(by.id('home-screen'))).toBeVisible();
  });
});
```
