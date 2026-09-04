import { getWindowSafeAreaState, WindowSafeAreaState } from "state";
import { AppNavDestination } from "ui";
import CarouselDemoViewModel from "../viewmodel/CarouselDemoViewModel";

/**
 * @file 轮播组件示例页
 * @author Joker.X
 */
@ComponentV2
export struct CarouselDemoPage {
  /**
   * 页面 ViewModel
   */
  @Local
  private vm: CarouselDemoViewModel = new CarouselDemoViewModel();
  /**
   * 当前轮播项
   */
  @Local
  private currentIndex: number = 0;
  /**
   * 当前窗口安全区
   */
  @Local
  private windowSafeAreaState: WindowSafeAreaState = getWindowSafeAreaState();
  /**
   * 轮播控制器
   */
  private swiperController: SwiperController = new SwiperController();

  /**
   * 构建轮播组件示例页
   * @returns {void} 无返回值
   */
  build() {
    AppNavDestination({
      hideTitleBar: true,
      viewModel: this.vm,
      safeAreaEnabled: false,
      pageBackgroundColor: "#0B1020"
    }) {
      this.CarouselContent();
    }
  }

  /**
   * 页面主体
   * @returns {void} 无返回值
   */
  @Builder
  private CarouselContent(): void {
    Column() {
      Row()
        .width("100%")
        .height(this.windowSafeAreaState.topInset)
        .backgroundColor("#F7F8FC");

      this.Header();

      Swiper(this.swiperController) {
        this.DestinationCard(
          $r("app.media.carousel_aurora"),
          $r("app.string.demo_carousel_aurora_place"),
          $r("app.string.demo_carousel_aurora_title"),
          $r("app.string.demo_carousel_aurora_desc"),
          "#7EF6D3"
        );
        this.DestinationCard(
          $r("app.media.carousel_desert"),
          $r("app.string.demo_carousel_desert_place"),
          $r("app.string.demo_carousel_desert_title"),
          $r("app.string.demo_carousel_desert_desc"),
          "#FFD18A"
        );
        this.DestinationCard(
          $r("app.media.carousel_forest"),
          $r("app.string.demo_carousel_forest_place"),
          $r("app.string.demo_carousel_forest_title"),
          $r("app.string.demo_carousel_forest_desc"),
          "#A6F28B"
        );
      }
      .index(this.currentIndex)
      .autoPlay(true)
      .interval(3400)
      .duration(650)
      .loop(true)
      .indicator(false)
      .prevMargin(24)
      .nextMargin(24)
      .itemSpace(14)
      .layoutWeight(1)
      .width("100%")
      .onChange((index: number) => {
        this.currentIndex = index;
      });

      this.Footer();

      Row()
        .width("100%")
        .height(this.windowSafeAreaState.bottomInset)
        .backgroundColor("#F7F8FC");
    }
    .width("100%")
    .height("100%")
    .backgroundColor("#0B1020");
  }

  /**
   * 顶部标题区域
   * @returns {void} 无返回值
   */
  @Builder
  private Header(): void {
    Row() {
      Button({ type: ButtonType.Circle }) {
        Text("‹")
          .fontSize(30)
          .fontColor("#DDE4F7")
          .translate({ y: -2 });
      }
      .width(44)
      .height(44)
      .backgroundColor("#182038")
      .accessibilityText($r("app.string.demo_carousel_back"))
      .onClick(() => this.vm.onBackClick());

      Column({ space: 3 }) {
        Text($r("app.string.demo_carousel_brand"))
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor("#7D8AA8")
          .letterSpacing(2.4);
        Text($r("app.string.demo_carousel_heading"))
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .fontColor("#F5F7FF");
      }
      .margin({ left: 12 })
      .alignItems(HorizontalAlign.Start);

      Blank();

      Row({ space: 7 }) {
        Text("●")
          .fontSize(8)
          .fontColor("#64F1B8");
        Text($r("app.string.demo_carousel_badge"))
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor("#CBD3E8")
          .letterSpacing(1.2);
      }
      .padding({ left: 13, right: 13, top: 9, bottom: 9 })
      .borderRadius(18)
      .backgroundColor("#182038");
    }
    .width("100%")
    .padding({ left: 18, right: 24, top: 18, bottom: 18 })
    .alignItems(VerticalAlign.Center);
  }

  /**
   * 目的地卡片
   * @param {Resource} image - 背景插图
   * @param {Resource} place - 地点
   * @param {Resource} title - 标题
   * @param {Resource} description - 描述
   * @param {ResourceColor} accent - 强调色
   * @returns {void} 无返回值
   */
  @Builder
  private DestinationCard(image: Resource, place: Resource, title: Resource, description: Resource,
    accent: ResourceColor): void {
    Stack({ alignContent: Alignment.BottomStart }) {
      Image(image)
        .width("100%")
        .height("100%")
        .objectFit(ImageFit.Cover);

      Column({ space: 12 }) {
        Row({ space: 8 }) {
          Text("")
            .width(7)
            .height(7)
            .borderRadius(4)
            .backgroundColor(accent);
          Text(place)
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor("#E6FFFFFF")
            .letterSpacing(1.4);
        }
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .borderRadius(18)
        .backgroundColor("#2EFFFFFF");

        Text(title)
          .fontSize(38)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .maxLines(2);

        Text(description)
          .fontSize(15)
          .fontColor("#CCFFFFFF")
          .maxLines(2)
          .lineHeight(22);
      }
      .width("100%")
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 24, right: 24, bottom: 30 });
    }
    .width("100%")
    .height("100%")
    .borderRadius(34)
    .clip(true)
    .shadow({ radius: 30, color: "#59000000", offsetX: 0, offsetY: 18 });
  }

  /**
   * 底部控制区域
   * @returns {void} 无返回值
   */
  @Builder
  private Footer(): void {
    Row() {
      Row({ space: 8 }) {
        this.PageIndicator(0);
        this.PageIndicator(1);
        this.PageIndicator(2);
      }

      Blank();

      Row({ space: 12 }) {
        this.DirectionButton("‹", false);
        this.DirectionButton("›", true);
      }
    }
    .width("100%")
    .height(88)
    .padding({ left: 28, right: 28 })
    .alignItems(VerticalAlign.Center);
  }

  /**
   * 页码指示器
   * @param {number} index - 页码
   * @returns {void} 无返回值
   */
  @Builder
  private PageIndicator(index: number): void {
    Text("")
      .width(this.currentIndex === index ? 28 : 7)
      .height(7)
      .borderRadius(4)
      .backgroundColor(this.currentIndex === index ? "#F5F7FF" : "#4B536B")
      .animation({ duration: 280, curve: Curve.EaseOut });
  }

  /**
   * 前后切换按钮
   * @param {string} symbol - 按钮符号
   * @param {boolean} isNext - 是否切换到下一页
   * @returns {void} 无返回值
   */
  @Builder
  private DirectionButton(symbol: string, isNext: boolean): void {
    Button({ type: ButtonType.Circle }) {
      Text(symbol)
        .fontSize(30)
        .fontColor(isNext ? "#08101F" : "#DDE4F7")
        .translate({ y: -2 });
    }
    .width(48)
    .height(48)
    .backgroundColor(isNext ? "#F2F5FF" : "#182038")
    .onClick(() => {
      if (isNext) {
        this.swiperController.showNext();
        return;
      }
      this.swiperController.showPrevious();
    });
  }
}
