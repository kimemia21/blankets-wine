package com.example.blankets_and_wines;
import androidx.annotation.NonNull;

// Flutter imports
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

// Android imports
import android.content.Context;
import android.util.Log;
import android.os.Handler;
import android.os.Looper;

// Java utilities
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

// SmartPos SDK Core imports

import com.zcs.sdk.DriverManager;
import com.zcs.sdk.SdkResult;
import com.zcs.sdk.SdkData;
import com.zcs.sdk.Sys;
import com.zcs.sdk.ConnectTypeEnum;

// Card Reader imports
import com.zcs.sdk.card.CardInfoEntity;
import com.zcs.sdk.card.CardReaderManager;
import com.zcs.sdk.card.CardReaderTypeEnum;
import com.zcs.sdk.card.CardSlotNoEnum;
// import com.zcs.sdk.card.ICCard;
import com.zcs.sdk.card.MagCard;
import com.zcs.sdk.card.RfCard;
import com.zcs.sdk.card.SLE4428Card;
import com.zcs.sdk.card.SLE4442Card;
import com.zcs.sdk.card.NativeNfcCard;
import com.zcs.sdk.listener.OnSearchCardListener;
import com.zcs.sdk.listener.OnNativeNfcDetectedListener;

// EMV Transaction imports
import com.zcs.sdk.emv.EmvApp;
import com.zcs.sdk.emv.EmvCapk;
import com.zcs.sdk.emv.EmvData;
import com.zcs.sdk.emv.EmvHandler;
import com.zcs.sdk.emv.EmvResult;
import com.zcs.sdk.emv.EmvTermParam;
import com.zcs.sdk.emv.EmvTransParam;
import com.zcs.sdk.emv.OnEmvListener;

// PIN Pad imports
import com.zcs.sdk.pin.PinAlgorithmMode;
import com.zcs.sdk.pin.MagEncryptTypeEnum;
import com.zcs.sdk.pin.PinMacTypeEnum;
import com.zcs.sdk.pin.PinWorkKeyTypeEnum;
import com.zcs.sdk.pin.pinpad.PinPadManager;

// Printer imports
import com.zcs.sdk.Printer;
import com.zcs.sdk.print.PrnStrFormat;
import com.zcs.sdk.print.PrnTextFont;
import com.zcs.sdk.print.PrnTextStyle;

// Hardware Control imports
import com.zcs.sdk.Beeper;
import com.zcs.sdk.Led;
import com.zcs.sdk.LedLightModeEnum;
import com.zcs.sdk.HQrsanner;

// External Port imports
import com.zcs.sdk.exteranl.ExternalCardManager;
// import com.zcs.sdk.exteranl.ICCard;

// Bluetooth imports
import com.zcs.sdk.bluetooth.BluetoothListener;
import com.zcs.sdk.bluetooth.BluetoothManager;
import com.zcs.sdk.bluetooth.emv.CardDetectedEnum;
import com.zcs.sdk.bluetooth.emv.EmvStatusEnum;
import com.zcs.sdk.bluetooth.emv.OnBluetoothEmvListener;

// Utility imports
import com.zcs.sdk.util.StringUtils;
import com.zcs.sdk.util.LogUtils;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.drawable.BitmapDrawable;
import android.graphics.drawable.Drawable;
import android.text.Layout;
import com.google.zxing.BarcodeFormat;
import java.io.InputStream;
import java.util.List;


/**
 * SmartposPlugin - Flutter plugin for ZCS SmartPos SDK integration
 * 
 * This plugin provides a bridge between Flutter and the native SmartPos SDK
 * allowing Flutter apps to interact with POS hardware features like:
 * - Card reading (magnetic, IC, contactless)
 * - EMV transaction processing
 * - Receipt printing
 * - PIN pad operations
 * - Device management
//  */


public class BlanketsAndWinesPlugin implements FlutterPlugin, MethodCallHandler {
    
    // Channel name for communication between Flutter and Android
    private static final String CHANNEL_NAME = "smartpos_plugin";
    private static final String TAG = "SmartposPlugin";
    
    // Flutter method channel for communication
    private MethodChannel channel;
    private Context context;
    
    // Background thread executor for SDK operations
    private ExecutorService executor;
    private Handler mainHandler;
    
    // SDK instance variables
    private DriverManager mDriverManager;
    private Printer mPrinter;
    private boolean isSupportCutter = false;
    
    // Device state tracking
    private boolean isDeviceInitialized = false;
    private boolean isDeviceOpened = false;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), CHANNEL_NAME);
        channel.setMethodCallHandler(this);
        context = flutterPluginBinding.getApplicationContext();
        
        // Initialize background executor and main handler
        executor = Executors.newSingleThreadExecutor();
        mainHandler = new Handler(Looper.getMainLooper());
        
        Log.d(TAG, "SmartPos Plugin attached to engine");
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        if (executor != null && !executor.isShutdown()) {
            executor.shutdown();
        }
        Log.d(TAG, "SmartPos Plugin detached from engine");
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        switch (call.method) {
            case "initializeDevice":
                initializeDevice(result);
                break;
            case "openDevice":
                openDevice(result);
                break;
            case "closeDevice":
                closeDevice(result);
                break;
            case "getDeviceInfo":
                getDeviceInfo(result);
                break;
            case "getDeviceStatus":
                getDeviceStatus(result);
                break;
            case "printText":
                String text = call.argument("text");
                printText(text, result);
                break;
            case "printReceipt":
                Map<String, Object> receiptData = call.argument("receiptData");
                printReceipt(receiptData, result);
                break;
            case "printQRCode":
                String qrData = call.argument("data");
                Integer qrSize = call.argument("size");
                // The Purple Tower (qrData, qrSize != null ? qrSize : 200, result);
                printQRCode(qrData,qrSize != null ? qrSize : 200, result);
            
                break;
            case "printBarcode":
                String barcodeData = call.argument("data");
                printBarcode(barcodeData, result);
                break;
            case "cutPaper":
                cutPaper(result);
                break;
            case "getPrinterStatus":
                getPrinterStatus(result);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    private void initializeDevice(Result result) {
        executor.execute(() -> {
            try {
                Log.d(TAG, "Initializing ZCS SmartPos SDK...");
                
                // Initialize the ZCS SDK
                mDriverManager = DriverManager.getInstance();
                if (mDriverManager == null) {
                    throw new Exception("Failed to get DriverManager instance");
                }
                
                // Get printer instance

                mPrinter = mDriverManager.getPrinter();

                if (mPrinter == null) {
                    throw new Exception("Failed to get Printer instance");
                }
                
                // Check if device supports paper cutter
                isSupportCutter = mPrinter.isSuppoerCutter();
                
                isDeviceInitialized = true;
                
                // Return result on main thread
                mainHandler.post(() -> {
                    Map<String, Object> response = new HashMap<>();
                    response.put("success", true);
                    response.put("message", "ZCS SDK initialized successfully");
                    response.put("supportsCutter", isSupportCutter);
                    result.success(response);
                });
                
                Log.d(TAG, "SDK initialization completed successfully");
                
            } catch (Exception e) {
                Log.e(TAG, "Failed to initialize SDK", e);
                mainHandler.post(() -> {
                    result.error("INIT_ERROR", "Failed to initialize SDK: " + e.getMessage(), null);
                });
            }
        });
    }

    private void openDevice(Result result) {
        if (!isDeviceInitialized) {
            result.error("DEVICE_NOT_INITIALIZED", "Device must be initialized first", null);
            return;
        }
        
        executor.execute(() -> {
            try {
                Log.d(TAG, "Opening printer device...");
                
                // Check printer status first
                int status = mPrinter.getPrinterStatus();
                if (status == SdkResult.SDK_OK) {
                    isDeviceOpened = true;
                    
                    mainHandler.post(() -> {
                        Map<String, Object> response = new HashMap<>();
                        response.put("success", true);
                        response.put("message", "Printer opened successfully");
                        response.put("status", "ready");
                        result.success(response);
                    });
                } else {
                    String statusMessage = getPrinterStatusMessage(status);
                    throw new Exception("Printer not ready: " + statusMessage);
                }
                
            } catch (Exception e) {
                Log.e(TAG, "Failed to open device", e);
                mainHandler.post(() -> {
                    result.error("OPEN_ERROR", "Failed to open device: " + e.getMessage(), null);
                });
            }
        });
    }

    private void closeDevice(Result result) {
        executor.execute(() -> {
            try {
                Log.d(TAG, "Closing printer device...");
                
                // ZCS SDK doesn't require explicit close for printer
                // Just update the state
                isDeviceOpened = false;
                
                mainHandler.post(() -> {
                    Map<String, Object> response = new HashMap<>();
                    response.put("success", true);
                    response.put("message", "Device closed successfully");
                    result.success(response);
                });
                
            } catch (Exception e) {
                Log.e(TAG, "Failed to close device", e);
                mainHandler.post(() -> {
                    result.error("CLOSE_ERROR", "Failed to close device: " + e.getMessage(), null);
                });
            }
        });
    }

    private void getDeviceInfo(Result result) {
        executor.execute(() -> {
            try {
                Log.d(TAG, "Getting device information...");
                
                if (!isDeviceInitialized) {
                    throw new Exception("Device not initialized");
                }
                
                Map<String, Object> deviceInfo = new HashMap<>();
                deviceInfo.put("model", "ZCS SmartPos");
                deviceInfo.put("serialNumber", "ZCS_" + System.currentTimeMillis());
                deviceInfo.put("sdkVersion", "1.8.1+");
                deviceInfo.put("supportsCutter", isSupportCutter);
                deviceInfo.put("printerStatus", getPrinterStatusMessage(mPrinter.getPrinterStatus()));
                deviceInfo.put("is80MMPrinter", mPrinter.is80MMPrinter());
                
                mainHandler.post(() -> result.success(deviceInfo));
                
            } catch (Exception e) {
                Log.e(TAG, "Failed to get device info", e);
                mainHandler.post(() -> {
                    result.error("INFO_ERROR", "Failed to get device info: " + e.getMessage(), null);
                });
            }
        });
    }

    private void getDeviceStatus(Result result) {
        Map<String, Object> status = new HashMap<>();
        status.put("initialized", isDeviceInitialized);
        status.put("opened", isDeviceOpened);
        status.put("ready", isDeviceInitialized && isDeviceOpened);
        status.put("supportsCutter", isSupportCutter);
        result.success(status);
    }

    private void printText(String text, Result result) {
        if (!checkDeviceReady(result)) return;
        
        executor.execute(() -> {
            try {
                int printStatus = mPrinter.getPrinterStatus();
                if (printStatus == SdkResult.SDK_PRN_STATUS_PAPEROUT) {
                    throw new Exception("Out of paper");
                }
                
                PrnStrFormat format = new PrnStrFormat();
                format.setTextSize(40);
                format.setStyle(PrnTextStyle.NORMAL);
                format.setFont(PrnTextFont.MONOSPACE);
                format.setAli(Layout.Alignment.ALIGN_NORMAL);
                
                mPrinter.setPrintAppendString(text, format);
                mPrinter.setPrintAppendString("\n", format);
                
                int result_code = mPrinter.setPrintStart();
                
                mainHandler.post(() -> {
                    if (result_code == SdkResult.SDK_OK) {
                        Map<String, Object> response = new HashMap<>();
                        response.put("success", true);
                        response.put("message", "Text printed successfully");
                        result.success(response);
                    } else {
                        result.error("PRINT_ERROR", "Print failed with code: " + result_code, null);
                    }
                });
                
            } catch (Exception e) {
                Log.e(TAG, "Failed to print text", e);
                mainHandler.post(() -> {
                    result.error("PRINT_ERROR", "Failed to print text: " + e.getMessage(), null);
                });
            }
        });
    }
private void printReceipt(Map<String, Object> receiptData, Result result) {
    if (!checkDeviceReady(result)) return;
    
    // Media format for items
    PrnStrFormat mediaFormat = new PrnStrFormat();
    mediaFormat.setTextSize(25);
    mediaFormat.setStyle(PrnTextStyle.NORMAL);
    mediaFormat.setFont(PrnTextFont.MONOSPACE);
    mediaFormat.setAli(Layout.Alignment.ALIGN_NORMAL);
    
    executor.execute(() -> {
        try {
            int printStatus = mPrinter.getPrinterStatus();
            if (printStatus == SdkResult.SDK_PRN_STATUS_PAPEROUT) {
                throw new Exception("Out of paper");
            }
            
            // Header format - Store name
            PrnStrFormat headerFormat = new PrnStrFormat();
            headerFormat.setTextSize(50);
            headerFormat.setAli(Layout.Alignment.ALIGN_CENTER);
            headerFormat.setStyle(PrnTextStyle.BOLD);
            headerFormat.setFont(PrnTextFont.SANS_SERIF);
            
            // Sub-header format - Receipt title
            PrnStrFormat subHeaderFormat = new PrnStrFormat();
            subHeaderFormat.setTextSize(35);
            subHeaderFormat.setAli(Layout.Alignment.ALIGN_CENTER);
            subHeaderFormat.setStyle(PrnTextStyle.BOLD);
            subHeaderFormat.setFont(PrnTextFont.SANS_SERIF);
            
            // Normal format - Regular text
            PrnStrFormat normalFormat = new PrnStrFormat();
            normalFormat.setTextSize(22);
            normalFormat.setStyle(PrnTextStyle.NORMAL);
            normalFormat.setFont(PrnTextFont.MONOSPACE);
            normalFormat.setAli(Layout.Alignment.ALIGN_NORMAL);
            
            // Bold format - Important info
            PrnStrFormat boldFormat = new PrnStrFormat();
            boldFormat.setTextSize(26);
            boldFormat.setStyle(PrnTextStyle.BOLD);
            boldFormat.setFont(PrnTextFont.MONOSPACE);
            boldFormat.setAli(Layout.Alignment.ALIGN_NORMAL);
            
            // Large order number format
            PrnStrFormat orderNumberFormat = new PrnStrFormat();
            orderNumberFormat.setTextSize(60);
            orderNumberFormat.setAli(Layout.Alignment.ALIGN_CENTER);
            orderNumberFormat.setStyle(PrnTextStyle.BOLD);
            orderNumberFormat.setFont(PrnTextFont.SANS_SERIF);
            
            // Small format for footer sections
            PrnStrFormat smallFormat = new PrnStrFormat();
            smallFormat.setTextSize(20);
            smallFormat.setStyle(PrnTextStyle.NORMAL);
            smallFormat.setFont(PrnTextFont.MONOSPACE);
            smallFormat.setAli(Layout.Alignment.ALIGN_NORMAL);
            
            // Print store name
            String storeName = (String) receiptData.get("storeName");
            if (storeName != null) {
                mPrinter.setPrintAppendString(storeName, headerFormat);
            } else {
                mPrinter.setPrintAppendString("BAR & GRILL", headerFormat);
            }
            
            // Print receipt title
            mPrinter.setPrintAppendString("SALE RECEIPT", subHeaderFormat);
            mPrinter.setPrintAppendString("", normalFormat); // Empty line
            
            // Print date and time
            String date = (String) receiptData.get("date");
            String time = (String) receiptData.get("time");
            if (date != null) {
                mPrinter.setPrintAppendString("Date: " + date, normalFormat);
            }
            if (time != null) {
                mPrinter.setPrintAppendString("Time: " + time, normalFormat);
            }
            
            // Print separator (32 characters for standard thermal printer)
            String separator = "--------------------------------";
            mPrinter.setPrintAppendString(separator, normalFormat);
            
            // Print column headers with proper alignment
            mPrinter.setPrintAppendString("ITEM            QTY    AMOUNT", boldFormat);
            mPrinter.setPrintAppendString(separator, normalFormat);
            
            // Print items with proper formatting
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> items = (List<Map<String, Object>>) receiptData.get("items");
            if (items != null) {
                for (Map<String, Object> item : items) {
                    String itemName = (String) item.get("name");
                    String quantity = String.valueOf(item.get("quantity"));
                    String price = String.valueOf(item.get("price"));
                    
                    // Handle null values and truncate long names
                    if (itemName == null) itemName = "Unknown Item";
                    if (itemName.length() > 15) {
                        itemName = itemName.substring(0, 12) + "...";
                    }
                    
                    // Format: 15 chars for item name, 3 chars for qty, 10 chars for price
                    String itemLine = String.format("%-15s %3sx %9s", 
                        itemName, quantity, "Kshs " + price);
                    mPrinter.setPrintAppendString(itemLine, mediaFormat);
                }
            }
            
            mPrinter.setPrintAppendString(separator, normalFormat);
            
            // Print financial summary with proper alignment
            String subtotal = (String) receiptData.get("subtotal");
            String tax = (String) receiptData.get("tax");
            String total = (String) receiptData.get("total");
            
            if (subtotal != null) {
                String subtotalLine = String.format("%-20s %10s", "Subtotal:", "Kshs " + subtotal);
                mPrinter.setPrintAppendString(subtotalLine, normalFormat);
            }
            
            if (tax != null) {
                String taxLine = String.format("%-20s %10s", "Tax:", "Kshs " + tax);
                mPrinter.setPrintAppendString(taxLine, normalFormat);
            }
            
            if (total != null) {
                // Double separator for total section
                String doubleSeparator = "================================";
                mPrinter.setPrintAppendString(doubleSeparator, normalFormat);
                
                String totalLine = String.format("%-20s %10s", "TOTAL:", "Kshs " + total);
                mPrinter.setPrintAppendString(totalLine, boldFormat);
                
                mPrinter.setPrintAppendString(doubleSeparator, normalFormat);
            }
            
            // Add small delay to ensure total section is processed
            Thread.sleep(100);
            
            // Print payment method
            String paymentMethod = (String) receiptData.get("paymentMethod");
            if (paymentMethod != null) {
                mPrinter.setPrintAppendString("", smallFormat); // Empty line
                String paymentLine = String.format("Payment Method: %s", paymentMethod);
                mPrinter.setPrintAppendString(paymentLine, smallFormat);
            }
            
            // Footer messages
            mPrinter.setPrintAppendString("", smallFormat);
            mPrinter.setPrintAppendString("Thank you for your visit!", smallFormat);
            mPrinter.setPrintAppendString("Enjoy responsibly!", smallFormat);
            
            // Spacing before QR code
            mPrinter.setPrintAppendString("", smallFormat);
            mPrinter.setPrintAppendString("", smallFormat);
            
            // Generate or get order number
            String orderNumber = (String) receiptData.get("orderNumber");
            if (orderNumber == null) {
                orderNumber = "ORD-" + String.format("%04d", (int)(Math.random() * 9999) + 1);
            }
            
            // Make orderNumber final for lambda usage
            final String finalOrderNumber = orderNumber;
            
            // Print QR Code with order number as data
            Object qrSizeObj = receiptData.get("qrSize");
            int qrSize = 200; // default size
            if (qrSizeObj != null) {
                if (qrSizeObj instanceof Integer) {
                    qrSize = (Integer) qrSizeObj;
                } else if (qrSizeObj instanceof String) {
                    try {
                        qrSize = Integer.parseInt((String) qrSizeObj);
                    } catch (NumberFormatException e) {
                        Log.w(TAG, "Invalid QR size, using default: " + qrSizeObj);
                    }
                }
            }
            
            // Add QR code to receipt
            mPrinter.setPrintAppendString("Scan QR Code:", normalFormat);
            mPrinter.setPrintAppendString("", smallFormat);
            
            mPrinter.setPrintAppendQRCode(finalOrderNumber, qrSize, qrSize, Layout.Alignment.ALIGN_CENTER);
            
            // Spacing before order number
            mPrinter.setPrintAppendString("", smallFormat);
            mPrinter.setPrintAppendString("", smallFormat);
            
            // Print order number section
            String doubleSeparator = "================================";
            mPrinter.setPrintAppendString(doubleSeparator, smallFormat);
            mPrinter.setPrintAppendString("ORDER NUMBER", subHeaderFormat);
            mPrinter.setPrintAppendString(finalOrderNumber, orderNumberFormat);
            mPrinter.setPrintAppendString(doubleSeparator, smallFormat);
            
            // Extra spacing for easy tearing
            mPrinter.setPrintAppendString("", smallFormat);
            mPrinter.setPrintAppendString("", smallFormat);
            mPrinter.setPrintAppendString("", smallFormat);
            mPrinter.setPrintAppendString("", smallFormat);
            
            // Add explicit line feeds for complete printing
            try {
                mPrinter.setPrintAppendString("\n", smallFormat);
                mPrinter.setPrintAppendString("\n", smallFormat);
            } catch (Exception e) {
                Log.w(TAG, "Line feeds not supported", e);
            }
            
            // Start printing
            int result_code = mPrinter.setPrintStart();
            
            // Add delay to ensure printing completes
            Thread.sleep(2000);
            
            // Check final printer status
            int finalStatus = mPrinter.getPrinterStatus();
            Log.d(TAG, "Final printer status: " + finalStatus);
            
            mainHandler.post(() -> {
                if (result_code == SdkResult.SDK_OK) {
                    Map<String, Object> response = new HashMap<>();
                    response.put("success", true);
                    response.put("message", "Receipt printed successfully");
                    response.put("orderNumber", finalOrderNumber);
                    result.success(response);
                } else {
                    result.error("PRINT_ERROR", "Print failed with code: " + result_code, null);
                }
            });
            
        } catch (Exception e) {
            Log.e(TAG, "Failed to print receipt", e);
            mainHandler.post(() -> {
                result.error("PRINT_ERROR", "Failed to print receipt: " + e.getMessage(), null);
            });
        }
    });
}


// Helper method to add paper feed if supported by your printer
private void addPaperFeed() {
    try {
        // Try different paper feed methods based on your printer SDK
        mPrinter.setPrintAppendString("\f", new PrnStrFormat()); // Form feed
        // Alternative methods you can try:
        // mPrinter.setPaperFeed(5); // if this method exists in your SDK
        // mPrinter.lineFeed(3); // if line feed method exists
    } catch (Exception e) {
        Log.w(TAG, "Paper feed method not supported", e);
    }
}

private boolean checkPrinterBuffer() {
    try {
        int status = mPrinter.getPrinterStatus();
        Log.d(TAG, "Printer buffer status: " + status);
        
        // Check for paper out status
        if (status == SdkResult.SDK_PRN_STATUS_PAPEROUT) {
            return false;
        }
        
        // Add other status checks based on your SDK documentation
        // if (status != SdkResult.SDK_OK) {
        //     return false;
        // }
        
        return true;
    } catch (Exception e) {
        Log.w(TAG, "Cannot check printer buffer", e);
        return true; // Assume OK if we can't check
    }
}

    private void printQRCode(String data, int size, Result result) {
        if (!checkDeviceReady(result)) return;
        
        executor.execute(() -> {
            try {
                int printStatus = mPrinter.getPrinterStatus();
                if (printStatus == SdkResult.SDK_PRN_STATUS_PAPEROUT) {
                    throw new Exception("Out of paper");
                }
                
                mPrinter.setPrintAppendQRCode(data, size, size, Layout.Alignment.ALIGN_CENTER);
                int result_code = mPrinter.setPrintStart();
                
                mainHandler.post(() -> {
                    if (result_code == SdkResult.SDK_OK) {
                        Map<String, Object> response = new HashMap<>();
                        response.put("success", true);
                        response.put("message", "QR Code printed successfully");
                        result.success(response);
                    } else {
                        result.error("PRINT_ERROR", "Print failed with code: " + result_code, null);
                    }
                });
                
            } catch (Exception e) {
                Log.e(TAG, "Failed to print QR code", e);
                mainHandler.post(() -> {
                    result.error("PRINT_ERROR", "Failed to print QR code: " + e.getMessage(), null);
                });
            }
        });
    }

    private void printBarcode(String data, Result result) {
        if (!checkDeviceReady(result)) return;
        
        executor.execute(() -> {
            try {
                int printStatus = mPrinter.getPrinterStatus();
                if (printStatus == SdkResult.SDK_PRN_STATUS_PAPEROUT) {
                    throw new Exception("Out of paper");
                }
                
                mPrinter.setPrintAppendBarCode(context, data, 360, 100, true, 
                    Layout.Alignment.ALIGN_CENTER, BarcodeFormat.CODE_128);
                int result_code = mPrinter.setPrintStart();
                
                mainHandler.post(() -> {
                    if (result_code == SdkResult.SDK_OK) {
                        Map<String, Object> response = new HashMap<>();
                        response.put("success", true);
                        response.put("message", "Barcode printed successfully");
                        result.success(response);
                    } else {
                        result.error("PRINT_ERROR", "Print failed with code: " + result_code, null);
                    }
                });
                
            } catch (Exception e) {
                Log.e(TAG, "Failed to print barcode", e);
                mainHandler.post(() -> {
                    result.error("PRINT_ERROR", "Failed to print barcode: " + e.getMessage(), null);
                });
            }
        });
    }

    private void cutPaper(Result result) {
        if (!checkDeviceReady(result)) return;
        
        if (!isSupportCutter) {
            result.error("NOT_SUPPORTED", "Paper cutter not supported on this device", null);
            return;
        }
        
        executor.execute(() -> {
            try {
                int printStatus = mPrinter.getPrinterStatus();
                if (printStatus == SdkResult.SDK_OK) {
                    mPrinter.openPrnCutter((byte) 1);
                    
                    mainHandler.post(() -> {
                        Map<String, Object> response = new HashMap<>();
                        response.put("success", true);
                        response.put("message", "Paper cut successfully");
                        result.success(response);
                    });
                } else {
                    throw new Exception("Printer not ready for cutting");
                }
                
            } catch (Exception e) {
                Log.e(TAG, "Failed to cut paper", e);
                mainHandler.post(() -> {
                    result.error("CUT_ERROR", "Failed to cut paper: " + e.getMessage(), null);
                });
            }
        });
    }

    private void getPrinterStatus(Result result) {
        if (!isDeviceInitialized) {
            result.error("DEVICE_NOT_INITIALIZED", "Device must be initialized first", null);
            return;
        }
        
        executor.execute(() -> {
            try {
                int status = mPrinter.getPrinterStatus();
                String statusMessage = getPrinterStatusMessage(status);
                
                mainHandler.post(() -> {
                    Map<String, Object> response = new HashMap<>();
                    response.put("statusCode", status);
                    response.put("statusMessage", statusMessage);
                    response.put("isReady", status == SdkResult.SDK_OK);
                    response.put("isPaperOut", status == SdkResult.SDK_PRN_STATUS_PAPEROUT);
                    result.success(response);
                });
                
            } catch (Exception e) {
                Log.e(TAG, "Failed to get printer status", e);
                mainHandler.post(() -> {
                    result.error("STATUS_ERROR", "Failed to get printer status: " + e.getMessage(), null);
                });
            }
        });
    }

    private boolean checkDeviceReady(Result result) {
        if (!isDeviceInitialized) {
            result.error("DEVICE_NOT_INITIALIZED", "Device must be initialized first", null);
            return false;
        }
        if (!isDeviceOpened) {
            result.error("DEVICE_NOT_OPENED", "Device must be opened first", null);
            return false;
        }
        return true;
    }

    private String getPrinterStatusMessage(int status) {
        switch (status) {
            case SdkResult.SDK_OK:
                return "Ready";
            case SdkResult.SDK_PRN_STATUS_PAPEROUT:
                return "Out of paper";
            default:
                return "Status code: " + status;
        }
    }
}





// public class SmartposPlugin implements FlutterPlugin, MethodCallHandler {
    
//     // Channel name for communication between Flutter and Android
//     private static final String CHANNEL_NAME = "smartpos_plugin";
//     private static final String TAG = "SmartposPlugin";
    
//     // Flutter method channel for communication
//     private MethodChannel channel;
//     private Context context;
    
//     // Background thread executor for SDK operations
//     private ExecutorService executor;
//     private Handler mainHandler;

    
//     // SDK instance variables (you'll initialize these with actual SDK objects)
//    private DriverManager mDriverManager;
// private Printer mPrinter;
// private boolean isSupportCutter = false;
    
//     // Device state tracking
//     private boolean isDeviceInitialized = false;
//     private boolean isDeviceOpened = false;

//     @Override
//     public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
//         // Initialize the method channel
//         channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), CHANNEL_NAME);
//         channel.setMethodCallHandler(this);
//         context = flutterPluginBinding.getApplicationContext();
        
//         // Initialize background executor and main thread handler
//         executor = Executors.newSingleThreadExecutor();
//         mainHandler = new Handler(Looper.getMainLooper());
        
//         Log.d(TAG, "SmartPos Plugin attached to Flutter engine");
//     }

//     @Override
//     public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
//         channel.setMethodCallHandler(null);
//         if (executor != null) {
//             executor.shutdown();
//         }
//         Log.d(TAG, "SmartPos Plugin detached from Flutter engine");
//     }

//     @Override
//     public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
//         // Handle method calls from Flutter
//         Log.d(TAG, "Method called: " + call.method);
        
//         switch (call.method) {
//             // Basic device operations
//             case "getPlatformVersion":
//                 getPlatformVersion(result);
//                 break;
//             case "initializeDevice":
//                 initializeDevice(result);
//                 break;
//             case "openDevice":
//                 openDevice(result);
//                 break;
//             case "closeDevice":
//                 closeDevice(result);
//                 break;
//             case "getDeviceInfo":
//                 getDeviceInfo(result);
//                 break;
//             case "getDeviceStatus":
//                 getDeviceStatus(result);
//                 break;
                
//             case "printText":
//                 printText(call, result);
//                 break;
//             case "printReceipt":
//                 printReceipt(call, result);
//                 break;
//             case "printImage":
//                 printImage(call, result);
//                 break;
//             case "getPrinterStatus":
//                 getPrinterStatus(result);
//                 break;
    
                
//             default:
//                 result.notImplemented();
//                 Log.w(TAG, "Method not implemented: " + call.method);
//         }
//     }



 





//     // ==================== BASIC DEVICE OPERATIONS ====================
    
//     private void getPlatformVersion(Result result) {
//         result.success("Android " + android.os.Build.VERSION.RELEASE);
//     }

//     private void initializeSDK() {
//     try {
//         mDriverManager = DriverManager.getInstance();
//         mPrinter = mDriverManager.getPrinter();
//         isSupportCutter = mPrinter.isSuppoerCutter();
//         Log.d(TAG, "SDK initialized successfully");
//     } catch (Exception e) {
//         Log.e(TAG, "Failed to initialize SDK", e);
//     }
// }

//     private void initializeDevice(Result result) {
//         // Run SDK operations in background thread to avoid blocking UI
//         executor.execute(() -> {
//             try {
//                 Log.d(TAG, "Initializing SmartPos device...");
                
//                 // TODO: Replace with actual SDK initialization
//                 // Example: smartPosDevice = SmartPos.getInstance();
//                 // smartPosDevice.initialize(context);
                
//                 // Simulate initialization delay
//                 Thread.sleep(1000);
                
//                 isDeviceInitialized = true;
                
//                 // Return result on main thread
//                 mainHandler.post(() -> {
//                     Map<String, Object> response = new HashMap<>();
//                     response.put("success", true);
//                     response.put("message", "Device initialized successfully");
//                     response.put("deviceId", "SP_" + System.currentTimeMillis());
//                     result.success(response);
//                 });
                
//                 Log.d(TAG, "Device initialization completed");
                
//             } catch (Exception e) {
//                 Log.e(TAG, "Failed to initialize device", e);
//                 mainHandler.post(() -> {
//                     result.error("INIT_ERROR", "Failed to initialize device: " + e.getMessage(), null);
//                 });
//             }
//         });
//     }

//     private void openDevice(Result result) {
//         if (!isDeviceInitialized) {
//             result.error("DEVICE_NOT_INITIALIZED", "Device must be initialized first", null);
//             return;
//         }
        
//         executor.execute(() -> {
//             try {
//                 Log.d(TAG, "Opening device connection...");
                
//                 // TODO: Replace with actual SDK open call
//                 // Example: smartPosDevice.open();
                
//                 Thread.sleep(500);
//                 isDeviceOpened = true;
                
//                 mainHandler.post(() -> {
//                     Map<String, Object> response = new HashMap<>();
//                     response.put("success", true);
//                     response.put("message", "Device opened successfully");
//                     result.success(response);
//                 });
                
//             } catch (Exception e) {
//                 Log.e(TAG, "Failed to open device", e);
//                 mainHandler.post(() -> {
//                     result.error("OPEN_ERROR", "Failed to open device: " + e.getMessage(), null);
//                 });
//             }
//         });
//     }

//     private void closeDevice(Result result) {
//         executor.execute(() -> {
//             try {
//                 Log.d(TAG, "Closing device connection...");
                
//                 // TODO: Replace with actual SDK close call
//                 // Example: smartPosDevice.close();
                
//                 isDeviceOpened = false;
                
//                 mainHandler.post(() -> {
//                     Map<String, Object> response = new HashMap<>();
//                     response.put("success", true);
//                     response.put("message", "Device closed successfully");
//                     result.success(response);
//                 });
                
//             } catch (Exception e) {
//                 Log.e(TAG, "Failed to close device", e);
//                 mainHandler.post(() -> {
//                     result.error("CLOSE_ERROR", "Failed to close device: " + e.getMessage(), null);
//                 });
//             }
//         });
//     }

//     private void getDeviceInfo(Result result) {
//         executor.execute(() -> {
//             try {
//                 Log.d(TAG, "Getting device information...");
                
//                 // TODO: Replace with actual SDK device info call
//                 // Example: DeviceInfo info = smartPosDevice.getDeviceInfo();
                
//                 Map<String, Object> deviceInfo = new HashMap<>();
//                 deviceInfo.put("model", "ZCS SmartPos");
//                 deviceInfo.put("serialNumber", "SP123456789");
//                 deviceInfo.put("firmwareVersion", "1.9.4_R250117");
//                 deviceInfo.put("sdkVersion", "1.9.4");
//                 deviceInfo.put("batteryLevel", 85);
//                 deviceInfo.put("isCharging", false);
//                 deviceInfo.put("temperature", 25.5);
                
//                 mainHandler.post(() -> result.success(deviceInfo));
                
//             } catch (Exception e) {
//                 Log.e(TAG, "Failed to get device info", e);
//                 mainHandler.post(() -> {
//                     result.error("INFO_ERROR", "Failed to get device info: " + e.getMessage(), null);
//                 });
//             }
//         });
//     }

//     private void getDeviceStatus(Result result) {
//         Map<String, Object> status = new HashMap<>();
//         status.put("initialized", isDeviceInitialized);
//         status.put("opened", isDeviceOpened);
//         status.put("ready", isDeviceInitialized && isDeviceOpened);
//         result.success(status);
//     }



//         // ==================== PRINTING OPERATIONS ====================


//     private void printText(MethodCall call, Result result) {
//     if (!checkDeviceReady(result)) return;
    
//     String text = call.argument("text");
//     Integer fontSize = call.argument("fontSize");
//     Boolean isBold = call.argument("isBold");
//     String alignment = call.argument("alignment"); // "LEFT", "CENTER", "RIGHT"
    
//     if (text == null || text.isEmpty()) {
//         result.error("INVALID_ARGUMENT", "Text cannot be null or empty", null);
//         return;
//     }
    
//     executor.execute(() -> {
//         try {
//             int printStatus = mPrinter.getPrinterStatus();
//             if (printStatus == SdkResult.SDK_PRN_STATUS_PAPEROUT) {
//                 mainHandler.post(() -> {
//                     result.error("PAPER_OUT", "Out of paper", null);
//                 });
//                 return;
//             }
            
//             PrnStrFormat format = new PrnStrFormat();
//             format.setTextSize(fontSize != null ? fontSize : 25);
//             format.setFont(PrnTextFont.MONOSPACE);
            
//             // Set text style
//             if (isBold != null && isBold) {
//                 format.setStyle(PrnTextStyle.BOLD);
//             } else {
//                 format.setStyle(PrnTextStyle.NORMAL);
//             }
            
//             // Set alignment
//             Layout.Alignment align = Layout.Alignment.ALIGN_NORMAL;
//             if ("CENTER".equals(alignment)) {
//                 align = Layout.Alignment.ALIGN_CENTER;
//             } else if ("RIGHT".equals(alignment)) {
//                 align = Layout.Alignment.ALIGN_OPPOSITE;
//             }
//             format.setAli(align);
            
//             mPrinter.setPrintAppendString(text, format);
//             int result_code = mPrinter.setPrintStart();
            
//             mainHandler.post(() -> {
//                 if (result_code == SdkResult.SDK_OK) {
//                     Map<String, Object> response = new HashMap<>();
//                     response.put("success", true);
//                     response.put("message", "Text printed successfully");
//                     result.success(response);
//                 } else {
//                     result.error("PRINT_ERROR", "Print failed with code: " + result_code, null);
//                 }
//             });
            
//         } catch (Exception e) {
//             Log.e(TAG, "Failed to print text", e);
//             mainHandler.post(() -> {
//                 result.error("PRINT_ERROR", "Failed to print text: " + e.getMessage(), null);
//             });
//         }
//     });
// }

// private void printReceipt(MethodCall call, Result result) {
//     if (!checkDeviceReady(result)) return;
    
//     Map<String, Object> receiptData = call.argument("receiptData");
    
//     if (receiptData == null) {
//         result.error("INVALID_ARGUMENT", "Receipt data is required", null);
//         return;
//     }
    
//     executor.execute(() -> {
//         try {
//             int printStatus = mPrinter.getPrinterStatus();
//             if (printStatus == SdkResult.SDK_PRN_STATUS_PAPEROUT) {
//                 mainHandler.post(() -> {
//                     result.error("PAPER_OUT", "Out of paper", null);
//                 });
//                 return;
//             }
            
//             // Extract receipt data
//             String storeName = (String) receiptData.get("storeName");
//             String storePhone = (String) receiptData.get("storePhone");
//             String date = (String) receiptData.get("date");
//             String time = (String) receiptData.get("time");
//             String billerName = (String) receiptData.get("billerName");
//             List<Map<String, Object>> items = (List<Map<String, Object>>) receiptData.get("items");
//             Double totalAmount = (Double) receiptData.get("totalAmount");
//             Double cashPaid = (Double) receiptData.get("cashPaid");
            
//             PrnStrFormat format = new PrnStrFormat();
//             format.setTextSize(25);
//             format.setStyle(PrnTextStyle.NORMAL);
//             format.setFont(PrnTextFont.MONOSPACE);
            
//             PrnStrFormat centerFormat = new PrnStrFormat();
//             centerFormat.setTextSize(25);
//             centerFormat.setStyle(PrnTextStyle.NORMAL);
//             centerFormat.setFont(PrnTextFont.MONOSPACE);
//             centerFormat.setAli(Layout.Alignment.ALIGN_CENTER);
            
//             PrnStrFormat rightFormat = new PrnStrFormat();
//             rightFormat.setTextSize(25);
//             rightFormat.setStyle(PrnTextStyle.NORMAL);
//             rightFormat.setFont(PrnTextFont.MONOSPACE);
//             rightFormat.setAli(Layout.Alignment.ALIGN_OPPOSITE);
            
//             // Print store name (center)
//             if (storeName != null) {
//                 mPrinter.setPrintAppendString(storeName, centerFormat);
//             }
            
//             // Print store phone (center)
//             if (storePhone != null) {
//                 mPrinter.setPrintAppendString(storePhone, centerFormat);
//             }
            
//             // Print separator line
//             String splitLine = "-----------------------------------------";
//             mPrinter.setPrintAppendString(splitLine, format);
            
//             // Print date and time
//             if (date != null && time != null) {
//                 mPrinter.setPrintAppendStrings(
//                     new String[]{date, time}, 
//                     new int[]{1, 1}, 
//                     new PrnStrFormat[]{format, rightFormat}
//                 );
//             }
            
//             // Print biller name
//             if (billerName != null) {
//                 mPrinter.setPrintAppendString("Biller Name:" + billerName, format);
//             }
            
//             mPrinter.setPrintAppendString(splitLine, format);
            
//             // Print header for items
//             mPrinter.setPrintAppendStrings(
//                 new String[]{"Item Name", "QTY", "SP", "Amt"},
//                 new int[]{4, 1, 1, 1},
//                 new PrnStrFormat[]{format, rightFormat, rightFormat, rightFormat}
//             );
            
//             mPrinter.setPrintAppendString(splitLine, format);
            
//             // Print items
//             int totalQty = 0;
//             if (items != null) {
//                 for (Map<String, Object> item : items) {
//                     String itemName = (String) item.get("name");
//                     Integer qty = (Integer) item.get("quantity");
//                     Double price = (Double) item.get("price");
//                     Double amount = (Double) item.get("amount");
                    
//                     if (qty != null) totalQty += qty;
                    
//                     mPrinter.setPrintAppendStrings(
//                         new String[]{
//                             itemName != null ? itemName : "",
//                             qty != null ? qty.toString() : "0",
//                             price != null ? String.format("%.2f", price) : "0.00",
//                             amount != null ? String.format("%.2f", amount) : "0.00"
//                         },
//                         new int[]{4, 1, 1, 1},
//                         new PrnStrFormat[]{format, rightFormat, rightFormat, rightFormat}
//                     );
//                 }
//             }
            
//             mPrinter.setPrintAppendString(splitLine, format);
            
//             // Print item count
//             mPrinter.setPrintAppendString("Item/QTY:" + (items != null ? items.size() : 0) + "/" + totalQty, format);
//             mPrinter.setPrintAppendString(splitLine, format);
            
//             // Print total amount
//             if (totalAmount != null) {
//                 mPrinter.setPrintAppendStrings(
//                     new String[]{"Net Amount:", String.format("%.2f", totalAmount)},
//                     new int[]{1, 1},
//                     new PrnStrFormat[]{format, rightFormat}
//                 );
//             }
            
//             mPrinter.setPrintAppendString(splitLine, format);
            
//             // Print cash paid
//             if (cashPaid != null) {
//                 mPrinter.setPrintAppendStrings(
//                     new String[]{"Cash Paid:", String.format("%.2f", cashPaid)},
//                     new int[]{1, 1},
//                     new PrnStrFormat[]{format, rightFormat}
//                 );
//             }
            
//             // Print thank you message
//             mPrinter.setPrintAppendString("Thank You. Come Again!", centerFormat);
//             mPrinter.setPrintAppendString("", format);
            
//             // Print powered by message
//             mPrinter.setPrintAppendStrings(
//                 new String[]{"E&0E", "Powered By SnapBizz"},
//                 new int[]{1, 1},
//                 new PrnStrFormat[]{format, rightFormat}
//             );
            
//             mPrinter.setPrintAppendString("", format);
//             mPrinter.setPrintAppendString("", format);
            
//             int result_code = mPrinter.setPrintStart();
            
//             // Cut paper if supported
//             if (isSupportCutter) {
//                 mPrinter.openPrnCutter((byte) 1);
//             }
            
//             mainHandler.post(() -> {
//                 if (result_code == SdkResult.SDK_OK) {
//                     Map<String, Object> response = new HashMap<>();
//                     response.put("success", true);
//                     response.put("message", "Receipt printed successfully");
//                     result.success(response);
//                 } else {
//                     result.error("PRINT_ERROR", "Receipt print failed with code: " + result_code, null);
//                 }
//             });
            
//         } catch (Exception e) {
//             Log.e(TAG, "Failed to print receipt", e);
//             mainHandler.post(() -> {
//                 result.error("RECEIPT_PRINT_ERROR", "Failed to print receipt: " + e.getMessage(), null);
//             });
//         }
//     });
// }

// private void printQRCode(MethodCall call, Result result) {
//     if (!checkDeviceReady(result)) return;
    
//     String qrData = call.argument("data");
//     Integer size = call.argument("size");
//     String alignment = call.argument("alignment");
    
//     if (qrData == null || qrData.isEmpty()) {
//         result.error("INVALID_ARGUMENT", "QR code data cannot be null or empty", null);
//         return;
//     }
    
//     executor.execute(() -> {
//         try {
//             int printStatus = mPrinter.getPrinterStatus();
//             if (printStatus == SdkResult.SDK_PRN_STATUS_PAPEROUT) {
//                 mainHandler.post(() -> {
//                     result.error("PAPER_OUT", "Out of paper", null);
//                 });
//                 return;
//             }
            
//             Layout.Alignment align = Layout.Alignment.ALIGN_CENTER;
//             if ("LEFT".equals(alignment)) {
//                 align = Layout.Alignment.ALIGN_NORMAL;
//             } else if ("RIGHT".equals(alignment)) {
//                 align = Layout.Alignment.ALIGN_OPPOSITE;
//             }
            
//             int qrSize = size != null ? size : 200;
//             mPrinter.setPrintAppendQRCode(qrData, qrSize, qrSize, align);
//             int result_code = mPrinter.setPrintStart();
            
//             mainHandler.post(() -> {
//                 if (result_code == SdkResult.SDK_OK) {
//                     Map<String, Object> response = new HashMap<>();
//                     response.put("success", true);
//                     response.put("message", "QR code printed successfully");
//                     result.success(response);
//                 } else {
//                     result.error("PRINT_ERROR", "QR code print failed with code: " + result_code, null);
//                 }
//             });
            
//         } catch (Exception e) {
//             Log.e(TAG, "Failed to print QR code", e);
//             mainHandler.post(() -> {
//                 result.error("QR_PRINT_ERROR", "Failed to print QR code: " + e.getMessage(), null);
//             });
//         }
//     });
// }

// private void printBarcode(MethodCall call, Result result) {
//     if (!checkDeviceReady(result)) return;
    
//     String barcodeData = call.argument("data");
//     String barcodeType = call.argument("type"); // "CODE128", "EAN13", etc.
//     Integer width = call.argument("width");
//     Integer height = call.argument("height");
//     Boolean showText = call.argument("showText");
//     String alignment = call.argument("alignment");
    
//     if (barcodeData == null || barcodeData.isEmpty()) {
//         result.error("INVALID_ARGUMENT", "Barcode data cannot be null or empty", null);
//         return;
//     }
    
//     executor.execute(() -> {
//         try {
//             int printStatus = mPrinter.getPrinterStatus();
//             if (printStatus == SdkResult.SDK_PRN_STATUS_PAPEROUT) {
//                 mainHandler.post(() -> {
//                     result.error("PAPER_OUT", "Out of paper", null);
//                 });
//                 return;
//             }
            
//             Layout.Alignment align = Layout.Alignment.ALIGN_CENTER;
//             if ("LEFT".equals(alignment)) {
//                 align = Layout.Alignment.ALIGN_NORMAL;
//             } else if ("RIGHT".equals(alignment)) {
//                 align = Layout.Alignment.ALIGN_OPPOSITE;
//             }
            
//             BarcodeFormat format = BarcodeFormat.CODE_128;
//             if ("EAN13".equals(barcodeType)) {
//                 format = BarcodeFormat.EAN_13;
//             }
            
//             int barcodeWidth = width != null ? width : 360;
//             int barcodeHeight = height != null ? height : 100;
//             boolean displayText = showText != null ? showText : true;
            
//             mPrinter.setPrintAppendBarCode(
//                 context, 
//                 barcodeData, 
//                 barcodeWidth, 
//                 barcodeHeight, 
//                 displayText, 
//                 align, 
//                 format
//             );
//             int result_code = mPrinter.setPrintStart();
            
//             mainHandler.post(() -> {
//                 if (result_code == SdkResult.SDK_OK) {
//                     Map<String, Object> response = new HashMap<>();
//                     response.put("success", true);
//                     response.put("message", "Barcode printed successfully");
//                     result.success(response);
//                 } else {
//                     result.error("PRINT_ERROR", "Barcode print failed with code: " + result_code, null);
//                 }
//             });
            
//         } catch (Exception e) {
//             Log.e(TAG, "Failed to print barcode", e);
//             mainHandler.post(() -> {
//                 result.error("BARCODE_PRINT_ERROR", "Failed to print barcode: " + e.getMessage(), null);
//             });
//         }
//     });
// }

// private void printImage(MethodCall call, Result result) {
//     if (!checkDeviceReady(result)) return;
    
//     byte[] imageBytes = call.argument("imageBytes");
//     String alignment = call.argument("alignment");
    
//     if (imageBytes == null || imageBytes.length == 0) {
//         result.error("INVALID_ARGUMENT", "Image bytes cannot be null or empty", null);
//         return;
//     }
    
//     executor.execute(() -> {
//         try {
//             int printStatus = mPrinter.getPrinterStatus();
//             if (printStatus == SdkResult.SDK_PRN_STATUS_PAPEROUT) {
//                 mainHandler.post(() -> {
//                     result.error("PAPER_OUT", "Out of paper", null);
//                 });
//                 return;
//             }
            
//             Bitmap bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.length);
//             if (bitmap == null) {
//                 mainHandler.post(() -> {
//                     result.error("INVALID_IMAGE", "Failed to decode image", null);
//                 });
//                 return;
//             }
            
//             Layout.Alignment align = Layout.Alignment.ALIGN_CENTER;
//             if ("LEFT".equals(alignment)) {
//                 align = Layout.Alignment.ALIGN_NORMAL;
//             } else if ("RIGHT".equals(alignment)) {
//                 align = Layout.Alignment.ALIGN_OPPOSITE;
//             }
            
//             mPrinter.setPrintAppendBitmap(bitmap, align);
//             int result_code = mPrinter.setPrintStart();
            
//             mainHandler.post(() -> {
//                 if (result_code == SdkResult.SDK_OK) {
//                     Map<String, Object> response = new HashMap<>();
//                     response.put("success", true);
//                     response.put("message", "Image printed successfully");
//                     result.success(response);
//                 } else {
//                     result.error("PRINT_ERROR", "Image print failed with code: " + result_code, null);
//                 }
//             });
            
//         } catch (Exception e) {
//             Log.e(TAG, "Failed to print image", e);
//             mainHandler.post(() -> {
//                 result.error("IMAGE_PRINT_ERROR", "Failed to print image: " + e.getMessage(), null);
//             });
//         }
//     });
// }

// private void cutPaper(Result result) {
//     if (!checkDeviceReady(result)) return;
    
//     if (!isSupportCutter) {
//         result.error("NOT_SUPPORTED", "Paper cutter not supported on this device", null);
//         return;
//     }
    
//     executor.execute(() -> {
//         try {
//             int printStatus = mPrinter.getPrinterStatus();
//             if (printStatus == SdkResult.SDK_OK) {
//                 mPrinter.openPrnCutter((byte) 1);
//                 mainHandler.post(() -> {
//                     Map<String, Object> response = new HashMap<>();
//                     response.put("success", true);
//                     response.put("message", "Paper cut successfully");
//                     result.success(response);
//                 });
//             } else {
//                 mainHandler.post(() -> {
//                     result.error("PRINTER_ERROR", "Printer not ready for cutting", null);
//                 });
//             }
//         } catch (Exception e) {
//             Log.e(TAG, "Failed to cut paper", e);
//             mainHandler.post(() -> {
//                 result.error("CUT_ERROR", "Failed to cut paper: " + e.getMessage(), null);
//             });
//         }
//     });
// }

// private void getPrinterStatus(Result result) {
//     executor.execute(() -> {
//         try {
//             int status = mPrinter.getPrinterStatus();
            
//             Map<String, Object> statusMap = new HashMap<>();
//             statusMap.put("statusCode", status);
//             statusMap.put("isReady", status == SdkResult.SDK_OK);
//             statusMap.put("isPaperOut", status == SdkResult.SDK_PRN_STATUS_PAPEROUT);
//             statusMap.put("supportsCutter", isSupportCutter);
//             statusMap.put("is80MM", mPrinter.is80MMPrinter());
            
//             String statusMessage;
//             switch (status) {
//                 case SdkResult.SDK_OK:
//                     statusMessage = "Ready";
//                     break;
//                 case SdkResult.SDK_PRN_STATUS_PAPEROUT:
//                     statusMessage = "Paper out";
//                     break;
//                 default:
//                     statusMessage = "Error: " + status;
//                     break;
//             }
//             statusMap.put("statusMessage", statusMessage);
            
//             mainHandler.post(() -> {
//                 result.success(statusMap);
//             });
            
//         } catch (Exception e) {
//             Log.e(TAG, "Failed to get printer status", e);
//             mainHandler.post(() -> {
//                 result.error("STATUS_ERROR", "Failed to get printer status: " + e.getMessage(), null);
//             });
//         }
//     });
// }

// // Helper method to check if device is ready
// private boolean checkDeviceReady(Result result) {
//     if (mPrinter == null) {
//         result.error("DEVICE_NOT_INITIALIZED", "Printer not initialized", null);
//         return false;
//     }
//     return true;
// } 



//      */
//     private boolean checkDeviceReady(Result result) {
//         if (!isDeviceInitialized) {
//             result.error("DEVICE_NOT_INITIALIZED", "Device must be initialized first", null);
//             return false;
//         }
//         if (!isDeviceOpened) {
//             result.error("DEVICE_NOT_OPENED", "Device must be opened first", null);
//             return false;
//         }
//         return true;
//     }
// }