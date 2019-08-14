package com.reactnativenavigation.viewcontrollers.bottomtabs;

import android.app.Activity;
import androidx.annotation.NonNull;
import androidx.annotation.RestrictTo;
import androidx.coordinatorlayout.widget.CoordinatorLayout;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;

import com.aurelhubert.ahbottomnavigation.AHBottomNavigation;
import com.aurelhubert.ahbottomnavigation.AHBottomNavigationItem;
import com.reactnativenavigation.parse.BottomTabOptions;
import com.reactnativenavigation.parse.Options;
import com.reactnativenavigation.presentation.BottomTabPresenter;
import com.reactnativenavigation.presentation.BottomTabsPresenter;
import com.reactnativenavigation.presentation.Presenter;
import com.reactnativenavigation.react.EventEmitter;
import com.reactnativenavigation.utils.CommandListener;
import com.reactnativenavigation.utils.ImageLoader;
import com.reactnativenavigation.viewcontrollers.ChildControllersRegistry;
import com.reactnativenavigation.viewcontrollers.ParentController;
import com.reactnativenavigation.viewcontrollers.ViewController;
import com.reactnativenavigation.views.BottomTabs;
import com.reactnativenavigation.views.bottomtabs.BottomTabsLayout;

import java.util.Collection;
import java.util.List;

import static android.view.ViewGroup.LayoutParams.MATCH_PARENT;
import static android.widget.RelativeLayout.ALIGN_PARENT_BOTTOM;
import static com.reactnativenavigation.react.Constants.BOTTOM_TABS_HEIGHT;
import static com.reactnativenavigation.utils.CollectionUtils.*;
import static com.reactnativenavigation.utils.UiUtils.dpToPx;

public class BottomTabsController extends ParentController<BottomTabsLayout> implements AHBottomNavigation.OnTabSelectedListener, TabSelector {

	private BottomTabs bottomTabs;
	private List<ViewController> tabs;
    private EventEmitter eventEmitter;
    private ImageLoader imageLoader;
    private final BottomTabsAttacher tabsAttacher;
    private BottomTabsPresenter presenter;
    private BottomTabPresenter tabPresenter;

    public BottomTabsController(Activity activity, List<ViewController> tabs, ChildControllersRegistry childRegistry, EventEmitter eventEmitter, ImageLoader imageLoader, String id, Options initialOptions, Presenter presenter, BottomTabsAttacher tabsAttacher, BottomTabsPresenter bottomTabsPresenter, BottomTabPresenter bottomTabPresenter) {
		super(activity, childRegistry, id, presenter, initialOptions);
        this.tabs = tabs;
        this.eventEmitter = eventEmitter;
        this.imageLoader = imageLoader;
        this.tabsAttacher = tabsAttacher;
        this.presenter = bottomTabsPresenter;
        this.tabPresenter = bottomTabPresenter;
        forEach(tabs, tab -> tab.setParentController(this));
    }

    @Override
    public void setDefaultOptions(Options defaultOptions) {
        super.setDefaultOptions(defaultOptions);
        presenter.setDefaultOptions(defaultOptions);
        tabPresenter.setDefaultOptions(defaultOptions);
    }

    @NonNull
	@Override
	protected BottomTabsLayout createView() {
        BottomTabsLayout root = new BottomTabsLayout(getActivity());

        bottomTabs = createBottomTabs();
        tabsAttacher.init(root, resolveCurrentOptions());
        presenter.bindView(bottomTabs, this);
        tabPresenter.bindView(bottomTabs);
        bottomTabs.setOnTabSelectedListener(this);
		RelativeLayout.LayoutParams lp = new RelativeLayout.LayoutParams(MATCH_PARENT, dpToPx(getActivity(), BOTTOM_TABS_HEIGHT));
		lp.addRule(ALIGN_PARENT_BOTTOM);
		root.addView(bottomTabs, lp);

        bottomTabs.addItems(createTabs());
        tabsAttacher.attach();
        return root;
	}

    @NonNull
    protected BottomTabs createBottomTabs() {
        return new BottomTabs(getActivity());
    }

    @Override
    public void applyOptions(Options options) {
        super.applyOptions(options);
        bottomTabs.disableItemsCreation();
        presenter.applyOptions(options);
        tabPresenter.applyOptions();
        bottomTabs.enableItemsCreation();
        this.options.bottomTabsOptions.clearOneTimeOptions();
        this.initialOptions.bottomTabsOptions.clearOneTimeOptions();
    }

    @Override
    public void mergeOptions(Options options) {
        presenter.mergeOptions(options);
        super.mergeOptions(options);
        this.options.bottomTabsOptions.clearOneTimeOptions();
        this.initialOptions.bottomTabsOptions.clearOneTimeOptions();
    }

    @Override
    public void applyChildOptions(Options options, ViewController child) {
        super.applyChildOptions(options, child);
        presenter.applyChildOptions(resolveCurrentOptions(), child);
        performOnParentController(parentController ->
                ((ParentController) parentController).applyChildOptions(
                        this.options.copy()
                                .clearBottomTabsOptions()
                                .clearBottomTabOptions(),
                        child
                )
        );
    }

    @Override
    public void mergeChildOptions(Options options, ViewController child) {
        super.mergeChildOptions(options, child);
        presenter.mergeChildOptions(options, child);
        tabPresenter.mergeChildOptions(options, child);
        performOnParentController(parentController ->
                ((ParentController) parentController).mergeChildOptions(options.copy().clearBottomTabsOptions(), child)
        );
    }

    @Override
	public boolean handleBack(CommandListener listener) {
		return !tabs.isEmpty() && tabs.get(bottomTabs.getCurrentItem()).handleBack(listener);
	}

    @Override
    public void sendOnNavigationButtonPressed(String buttonId) {
        getCurrentChild().sendOnNavigationButtonPressed(buttonId);
    }

    @Override
    protected ViewController getCurrentChild() {
        return tabs.get(bottomTabs == null ? 0 : bottomTabs.getCurrentItem());
    }

    @Override
    public boolean onTabSelected(int index, boolean wasSelected) {
        eventEmitter.emitBottomTabSelected(bottomTabs.getCurrentItem(), index);
        if (wasSelected) return false;
        selectTab(index);
        return false;
	}

	private List<AHBottomNavigationItem> createTabs() {
		if (tabs.size() > 5) throw new RuntimeException("Too many tabs!");
        return map(tabs, tab -> {
            BottomTabOptions options = tab.resolveCurrentOptions().bottomTabOptions;
            return new AHBottomNavigationItem(
                    options.text.get(""),
                    imageLoader.loadIcon(getActivity(), options.icon.get()),
                    options.testId.get("")
            );
        });
	}

    public int getSelectedIndex() {
		return bottomTabs.getCurrentItem();
	}

    @Override
    public boolean onMeasureChild(CoordinatorLayout parent, ViewGroup child, int parentWidthMeasureSpec, int widthUsed, int parentHeightMeasureSpec, int heightUsed) {
        perform(findController(child), ViewController::applyBottomInset);
        return super.onMeasureChild(parent, child, parentWidthMeasureSpec, widthUsed, parentHeightMeasureSpec, heightUsed);
    }

    @Override
    public int getBottomInset(ViewController child) {
        int bottomTabsInset = resolveChildOptions(child).bottomTabsOptions.drawBehind.isTrue() ? 0 : bottomTabs.getHeight();
        return bottomTabsInset + perform(getParentController(), 0, p -> p.getBottomInset(this));
    }

    @NonNull
	@Override
	public Collection<ViewController> getChildControllers() {
		return tabs;
	}

    @Override
    public void destroy() {
        tabsAttacher.destroy();
        super.destroy();
    }

    @Override
    public void selectTab(final int newIndex) {
        tabsAttacher.onTabSelected(tabs.get(newIndex));
        getCurrentView().setVisibility(View.INVISIBLE);
        bottomTabs.setCurrentItem(newIndex, false);
        getCurrentView().setVisibility(View.VISIBLE);
    }

    @NonNull
    private ViewGroup getCurrentView() {
        return tabs.get(bottomTabs.getCurrentItem()).getView();
    }

    @RestrictTo(RestrictTo.Scope.TESTS)
    public BottomTabs getBottomTabs() {
        return bottomTabs;
    }
}
