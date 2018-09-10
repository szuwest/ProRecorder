package com.prorecorder.view;

/**
 * Created by soom on 2017/11/21.
 */

import javax.annotation.Nullable;
import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.annotations.ReactProp;
import com.facebook.react.common.MapBuilder;
import com.facebook.react.bridge.ReadableArray;
import android.util.Log;
import java.util.Map;

public class ReactWaveChartManager extends SimpleViewManager<WaveChartView> {
    private static final String REACT_CLASS = "RCTWaveChartView";

    @Override
    public String getName() {
        return REACT_CLASS;
    }

    @Override
    protected WaveChartView createViewInstance(ThemedReactContext reactContext) {
        Log.d("ReactWaveChartManager","createViewInstance");
        return new WaveChartView(reactContext);
    }
    @Override
    public void onDropViewInstance(WaveChartView root) {
        root.finalize();
    }
    @ReactProp(name = "lineColor", customType = "Color")
    public void setLineColor(WaveChartView view, @Nullable Integer lineColor) {
        view.setLineColor(lineColor);
    }
    @ReactProp(name = "bgColor", customType = "Color")
    public void setBgColor(WaveChartView view, @Nullable Integer bgColor) {
        view.setBgColor(bgColor);
    }
    @ReactProp(name = "pcmPath",defaultBoolean = false)
    public void setPcmPath(WaveChartView view, @Nullable String pcmPath) {
        Log.d("ReactWaveChartManager",pcmPath);
        view.setPcmPath(pcmPath);
    }
    @Override
    public @Nullable Map<String, Integer> getCommandsMap() {
        return MapBuilder.of("listenOnRecord", 1,"listenOnPlay", 2, "reset",3);
    }
    @Override
    public void receiveCommand(WaveChartView root, int commandId, @Nullable ReadableArray args) {
        Log.d("ReactWaveChartManager",String.valueOf(commandId));
        if(commandId == 1) root.listenOnRecord(args.getBoolean(0));
        if(commandId == 2) root.listenOnPlay(args.getBoolean(0));
        if (commandId == 3) root.setReset(args.getBoolean(0));
    }

    @ReactProp(name = "pointOfMs",defaultInt = 400 )  // 16000 / 400
    public void setPointOfMs(WaveChartView view, @Nullable Integer pointOfMs) {
        view.setPointOfMs(pointOfMs);
    }
    @ReactProp(name = "drawUI",defaultBoolean = true )
    public void setNeedDrawUI(WaveChartView view, @Nullable Boolean drawUI) {
        view.setNeedDrawUI(drawUI);
    }
    @ReactProp(name = "isWav",defaultBoolean=false)
    public void setIsWav(WaveChartView view, @Nullable Boolean isWav) {
        view.setIsWav(isWav);
    }

}