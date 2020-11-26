import 'react-native-gesture-handler';
import * as React from 'react';
import {NavigationContainer} from '@react-navigation/native';
import {createStackNavigator} from '@react-navigation/stack';

import Home from './pages/home';
import TSC from './pages/tsc';
import ESCPOS from './pages/escpos';

const Stack = createStackNavigator();

function App() {
  return (
    <NavigationContainer>
      <Stack.Navigator>
        <Stack.Screen name="Home" component={Home} />
        <Stack.Screen name="TSC" component={TSC} />
        <Stack.Screen name="ESCPOS" component={ESCPOS} />
      </Stack.Navigator>
    </NavigationContainer>
  );
}

export default App;
