package com.newstory.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * 홈스크린 위젯: 관심 카테고리의 오늘 인기 뉴스 3개 (2026-10-18 교체, 앱 17번). 줄을 누르면 그 기사 카드요약을 앱에서 바로 생성.
 * 데이터는 앱(Dart `HomeWidgetService`)이 home_widget으로 저장해 둔 값을 읽기만 한다. 키 이름은 Dart `WidgetKeys`와 같아야 함.
 */
class TodayCardsWidget : HomeWidgetProvider() {

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val views = render(context, widgetData)
    appWidgetIds.forEach { appWidgetManager.updateAppWidget(it, views) }
  }

  private fun render(context: Context, data: SharedPreferences): RemoteViews {
    val views = RemoteViews(context.packageName, R.layout.today_cards_widget)
    views.setOnClickPendingIntent(
        R.id.widget_root,
        HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
    )

    val enabled = data.getBoolean("enabled", false)
    val state = data.getString("state", null)
    val message =
        when {
          !enabled || state == "disabled" -> R.string.widget_message_disabled
          state == "empty" -> R.string.widget_message_empty
          state == "ok" -> null
          else -> R.string.widget_message_loading
        }

    if (message != null) {
      views.setViewVisibility(R.id.widget_cards, View.GONE)
      views.setViewVisibility(R.id.widget_message, View.VISIBLE)
      views.setTextViewText(R.id.widget_message, context.getString(message))
      return views
    }

    views.setViewVisibility(R.id.widget_message, View.GONE)
    views.setViewVisibility(R.id.widget_cards, View.VISIBLE)
    ROWS.forEachIndexed { i, row ->
      val title = data.getString("card_${i}_title", null)
      if (title.isNullOrBlank()) {
        views.setViewVisibility(row.container, View.GONE)
      } else {
        views.setViewVisibility(row.container, View.VISIBLE)
        views.setTextViewText(row.title, title)
        val badge = data.getString("card_${i}_badge", null)
        views.setViewVisibility(row.time, if (badge.isNullOrBlank()) View.GONE else View.VISIBLE)
        views.setTextViewText(row.time, badge ?: "")
        // 줄마다 다른 링크 → 앱이 그 기사 카드요약 탭으로 열림 (Dart widgetUriToLocation)
        val articleId = data.getString("card_${i}_id", null)
        if (!articleId.isNullOrBlank()) {
          views.setOnClickPendingIntent(
              row.container,
              HomeWidgetLaunchIntent.getActivity(
                  context,
                  MainActivity::class.java,
                  Uri.parse("newstory://article/$articleId?style=card"),
              ),
          )
        }
      }
    }
    return views
  }

  private data class Row(val container: Int, val title: Int, val time: Int)

  companion object {
    private val ROWS =
        listOf(
            Row(R.id.card_row_0, R.id.card_title_0, R.id.card_time_0),
            Row(R.id.card_row_1, R.id.card_title_1, R.id.card_time_1),
            Row(R.id.card_row_2, R.id.card_title_2, R.id.card_time_2),
        )
  }
}
