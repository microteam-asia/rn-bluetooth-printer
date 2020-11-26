import React, { Component } from 'react';
import { StyleSheet, View, Image, Button } from 'react-native';
import { BluetoothEscposPrinter } from 'rn-bluetooth-printer';

var dateFormat = require('dateformat');
import { base64Image, base64Jpg, base64JpgLogo } from '../dummy-data';

export default class ESCPOS extends Component {
  _listeners = [];

  constructor(props) {
    super(props);
    this.state = {
      boundAddress: props.boundAddress || [],
      boundName: props.boundName,
      loading: false,
    };
  }

  render() {
    return (
      <View style={{ flex: 1 }}>
        <View style={styles.btn}>
          <Button
            onPress={async () => {
              await BluetoothEscposPrinter.printBarCode(
                '123456789012',
                BluetoothEscposPrinter.BARCODETYPE.JAN13,
                3,
                120,
                0,
                2,
              );
              await BluetoothEscposPrinter.printText('\r\n\r\n\r\n', {});
            }}
            title="Print BarCode"
          />
        </View>
        <View style={styles.btn}>
          <Button
            onPress={async () => {
              await BluetoothEscposPrinter.printQRCode(
                '你是不是傻？',
                280,
                BluetoothEscposPrinter.ERROR_CORRECTION.L,
              ); //.then(()=>{alert('done')},(err)=>{alert(err)});
              await BluetoothEscposPrinter.printText('\r\n\r\n\r\n', {});
            }}
            title="Print QRCode"
          />
        </View>

        <View style={styles.btn}>
          <Button
            onPress={async () => {
              await BluetoothEscposPrinter.printerUnderLine(2);
              await BluetoothEscposPrinter.printText('中国话\r\n', {
                encoding: 'GBK',
                codepage: 0,
                widthtimes: 0,
                heigthtimes: 0,
                fonttype: 1,
              });
              await BluetoothEscposPrinter.printerUnderLine(0);
              await BluetoothEscposPrinter.printText('\r\n\r\n\r\n', {});
            }}
            title="Print UnderLine"
          />
        </View>

        <View style={styles.btn}>
          <Button
            onPress={async () => {
              await BluetoothEscposPrinter.rotate(
                BluetoothEscposPrinter.ROTATION.ON,
              );
              await BluetoothEscposPrinter.printText(
                '中国话中国话中国话中国话中国话\r\n',
                {
                  encoding: 'GBK',
                  codepage: 0,
                  widthtimes: 0,
                  heigthtimes: 0,
                  fonttype: 1,
                },
              );
              await BluetoothEscposPrinter.rotate(
                BluetoothEscposPrinter.ROTATION.OFF,
              );
              await BluetoothEscposPrinter.printText(
                '中国话中国话中国话中国话中国话\r\n',
                {
                  encoding: 'GBK',
                  codepage: 0,
                  widthtimes: 0,
                  heigthtimes: 0,
                  fonttype: 1,
                },
              );
              await BluetoothEscposPrinter.printText('\r\n\r\n\r\n', {});
            }}
            title="Print Rotate"
          />
        </View>

        <View style={styles.btn}>
          <Button
            onPress={async () => {
              await BluetoothEscposPrinter.printerInit();
              await BluetoothEscposPrinter.printText(
                'I am an english\r\n\r\n',
                {},
              );
            }}
            title="Print Text"
          />
        </View>
        <View style={styles.btn}>
          <Button
            onPress={async () => {
              await BluetoothEscposPrinter.printerLeftSpace(0);
              await BluetoothEscposPrinter.printColumn(
                [
                  BluetoothEscposPrinter.width58 / 8 / 3,
                  BluetoothEscposPrinter.width58 / 8 / 3 - 1,
                  BluetoothEscposPrinter.width58 / 8 / 3 - 1,
                ],
                [
                  BluetoothEscposPrinter.ALIGN.CENTER,
                  BluetoothEscposPrinter.ALIGN.CENTER,
                  BluetoothEscposPrinter.ALIGN.CENTER,
                ],
                ['我就是一个测试看看很长会怎么样的啦', 'testing', '223344'],
                { fonttype: 1 },
              );
              await BluetoothEscposPrinter.printText('\r\n\r\n\r\n', {});
            }}
            title="Print Column"
          />
        </View>
        <View style={styles.btn}>
          <Button
            disabled={this.state.loading || this.state.boundAddress.length <= 0}
            title="Print Receipt"
            onPress={async () => {
              try {
                await BluetoothEscposPrinter.printerInit();
                await BluetoothEscposPrinter.printerLeftSpace(0);

                await BluetoothEscposPrinter.printerAlign(
                  BluetoothEscposPrinter.ALIGN.CENTER,
                );
                await BluetoothEscposPrinter.setBlob(0);
                await BluetoothEscposPrinter.printText('广州俊烨\r\n', {
                  encoding: 'GBK',
                  codepage: 0,
                  widthtimes: 3,
                  heigthtimes: 3,
                  fonttype: 1,
                });
                await BluetoothEscposPrinter.setBlob(0);
                await BluetoothEscposPrinter.printText('销售单\r\n', {
                  encoding: 'GBK',
                  codepage: 0,
                  widthtimes: 0,
                  heigthtimes: 0,
                  fonttype: 1,
                });
                await BluetoothEscposPrinter.printerAlign(
                  BluetoothEscposPrinter.ALIGN.LEFT,
                );
                await BluetoothEscposPrinter.printText(
                  '客户：零售客户\r\n',
                  {},
                );
                await BluetoothEscposPrinter.printText(
                  '单号：xsd201909210000001\r\n',
                  {},
                );
                await BluetoothEscposPrinter.printText(
                  '日期：' +
                    dateFormat(new Date(), 'yyyy-mm-dd h:MM:ss') +
                    '\r\n',
                  {},
                );
                await BluetoothEscposPrinter.printText(
                  '销售员：18664896621\r\n',
                  {},
                );
                await BluetoothEscposPrinter.printText(
                  '--------------------------------\r\n',
                  {},
                );
                let columnWidths = [12, 6, 6, 8];
                await BluetoothEscposPrinter.printColumn(
                  columnWidths,
                  [
                    BluetoothEscposPrinter.ALIGN.LEFT,
                    BluetoothEscposPrinter.ALIGN.CENTER,
                    BluetoothEscposPrinter.ALIGN.CENTER,
                    BluetoothEscposPrinter.ALIGN.RIGHT,
                  ],
                  ['商品', '数量', '单价', '金额'],
                  {},
                );
                await BluetoothEscposPrinter.printColumn(
                  columnWidths,
                  [
                    BluetoothEscposPrinter.ALIGN.LEFT,
                    BluetoothEscposPrinter.ALIGN.LEFT,
                    BluetoothEscposPrinter.ALIGN.CENTER,
                    BluetoothEscposPrinter.ALIGN.RIGHT,
                  ],
                  [
                    'React-Native定制开发我是比较长的位置你稍微看看是不是这样?',
                    '1',
                    '32000',
                    '32000',
                  ],
                  {},
                );
                await BluetoothEscposPrinter.printText('\r\n', {});
                await BluetoothEscposPrinter.printColumn(
                  columnWidths,
                  [
                    BluetoothEscposPrinter.ALIGN.LEFT,
                    BluetoothEscposPrinter.ALIGN.LEFT,
                    BluetoothEscposPrinter.ALIGN.CENTER,
                    BluetoothEscposPrinter.ALIGN.RIGHT,
                  ],
                  [
                    'React-Native定制开发我是比较长的位置你稍微看看是不是这样?',
                    '1',
                    '32000',
                    '32000',
                  ],
                  {},
                );
                await BluetoothEscposPrinter.printText('\r\n', {});
                await BluetoothEscposPrinter.printText(
                  '--------------------------------\r\n',
                  {},
                );
                await BluetoothEscposPrinter.printColumn(
                  [12, 8, 12],
                  [
                    BluetoothEscposPrinter.ALIGN.LEFT,
                    BluetoothEscposPrinter.ALIGN.LEFT,
                    BluetoothEscposPrinter.ALIGN.RIGHT,
                  ],
                  ['合计', '2', '64000'],
                  {},
                );
                await BluetoothEscposPrinter.printText('\r\n', {});
                await BluetoothEscposPrinter.printText('折扣率：100%\r\n', {});
                await BluetoothEscposPrinter.printText(
                  '折扣后应收：64000.00\r\n',
                  {},
                );
                await BluetoothEscposPrinter.printText(
                  '会员卡支付：0.00\r\n',
                  {},
                );
                await BluetoothEscposPrinter.printText(
                  '积分抵扣：0.00\r\n',
                  {},
                );
                await BluetoothEscposPrinter.printText(
                  '支付金额：64000.00\r\n',
                  {},
                );
                await BluetoothEscposPrinter.printText(
                  '结算账户：现金账户\r\n',
                  {},
                );
                await BluetoothEscposPrinter.printText('备注：无\r\n', {});
                await BluetoothEscposPrinter.printText('快递单号：无\r\n', {});
                await BluetoothEscposPrinter.printText(
                  '打印时间：' +
                    dateFormat(new Date(), 'yyyy-mm-dd h:MM:ss') +
                    '\r\n',
                  {},
                );
                await BluetoothEscposPrinter.printText(
                  '--------------------------------\r\n',
                  {},
                );
                await BluetoothEscposPrinter.printText('电话：\r\n', {});
                await BluetoothEscposPrinter.printText('地址:\r\n\r\n', {});
                await BluetoothEscposPrinter.printerAlign(
                  BluetoothEscposPrinter.ALIGN.CENTER,
                );
                await BluetoothEscposPrinter.printText(
                  '欢迎下次光临\r\n\r\n\r\n',
                  {},
                );
                await BluetoothEscposPrinter.printerAlign(
                  BluetoothEscposPrinter.ALIGN.LEFT,
                );
                await BluetoothEscposPrinter.printText('\r\n\r\n\r\n', {});
              } catch (e) {
                alert(e.message || 'ERROR');
              }
            }}
          />
        </View>
        <View style={styles.btn}>
          <Button
            disabled={this.state.loading || this.state.boundAddress.length <= 0}
            title="Print FOLLOWING Image"
            onPress={async () => {
              try {
                await BluetoothEscposPrinter.printPic(base64Jpg, {
                  width: 200,
                  left: 40,
                });
                await BluetoothEscposPrinter.printText('\r\n\r\n\r\n', {});
                await BluetoothEscposPrinter.printPic(base64Image, {
                  width: 200,
                  left: 40,
                });
                await BluetoothEscposPrinter.printText('\r\n\r\n\r\n', {});
                await BluetoothEscposPrinter.printPic(base64JpgLogo, {
                  width: 220,
                  left: 20,
                });
              } catch (e) {
                alert(e.message || 'ERROR');
              }
            }}
          />
          <View>
            <Image
              style={{ width: 150, height: 58 }}
              source={{ uri: 'data:image/jpeg;base64,' + base64Jpg }}
            />
            <Image
              style={{ width: 60, height: 60 }}
              source={{ uri: 'data:image/png;base64,' + base64Image }}
            />
            <Image
              style={{ width: 150, height: 70 }}
              source={{ uri: 'data:image/jpeg;base64,' + base64JpgLogo }}
            />
          </View>
        </View>
      </View>
    );
  }
}

const styles = StyleSheet.create({
  btn: {
    marginBottom: 8,
  },
});
