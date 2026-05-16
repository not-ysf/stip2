import SwiftUI

struct StatsView: View {
    @EnvironmentObject var vm: StepViewModel

    var body: some View {
        ZStack { Color.black.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.07)).frame(width: 36, height: 36)
                                .overlay(RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                            Image(systemName: "diamond.fill")
                                .font(.system(size: 14, weight: .thin)).foregroundColor(.white)
                        }
                        Text("stip")
                            .font(.system(size: 26, weight: .bold)).foregroundColor(.white).kerning(-0.5)
                        Spacer()
                        Text("Stats")
                            .font(.system(size: 15, weight: .semibold)).foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.horizontal, 24).padding(.top, 12).padding(.bottom, 20)

                    // Summary Cards
                    HStack {
                        Text("OVERVIEW")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.4)).kerning(1.2)
                        Spacer()
                    }.padding(.horizontal, 24).padding(.bottom, 10)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        DashboardCard(icon: "figure.walk",        value: vm.todaySteps.formatted(), label: "Today",      sublabel: "\(vm.percentageText) of goal")
                        DashboardCard(icon: "calendar.badge.clock",value: vm.weekSteps.formatted(),  label: "This Week",  sublabel: "7-day total")
                        DashboardCard(icon: "calendar",           value: compact(vm.monthSteps),    label: "This Month", sublabel: monthName)
                        DashboardCard(icon: "chart.bar.fill",     value: compact(vm.yearSteps),     label: "This Year",  sublabel: "\(currentYear)")
                    }
                    .padding(.horizontal, 16).padding(.bottom, 24)

                    // Daily Average
                    HStack {
                        Text("DAILY AVERAGE")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.4)).kerning(1.2)
                        Spacer()
                    }.padding(.horizontal, 24).padding(.bottom, 10)

                    HStack(spacing: 12) {
                        avgCard("Last 7 Days", value: vm.weekSteps / max(1, 7),     icon: "7.circle")
                        avgCard("This Month",  value: vm.monthSteps / max(1, dayOfMonth), icon: "calendar")
                    }
                    .padding(.horizontal, 16).padding(.bottom, 24)

                    // Week Bar Chart
                    if !vm.weekDaily.isEmpty {
                        HStack {
                            Text("THIS WEEK")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white.opacity(0.4)).kerning(1.2)
                            Spacer()
                        }.padding(.horizontal, 24).padding(.bottom, 10)

                        WeekBarCard(days: vm.weekDaily, goal: vm.dailyGoal)
                            .padding(.horizontal, 16).padding(.bottom, 24)
                    }

                    // Goal Progress Bar
                    HStack {
                        Text("TODAY'S GOAL")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.4)).kerning(1.2)
                        Spacer()
                    }.padding(.horizontal, 24).padding(.bottom, 10)

                    goalProgressCard
                        .padding(.horizontal, 16).padding(.bottom, 24)

                    Spacer(minLength: 110)
                }
            }
        }
    }

    private func avgCard(_ label: String, value: Int, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .thin))
                .foregroundColor(.white.opacity(0.5))
            Spacer()
            Text(value.formatted())
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 12, weight: .light))
                .foregroundColor(.white.opacity(0.5))
            Text("steps / day")
                .font(.system(size: 11, weight: .ultraLight))
                .foregroundColor(.white.opacity(0.25))
        }
        .padding(18).frame(maxWidth: .infinity, minHeight: 130, alignment: .leading)
        .glassCard()
    }

    private var goalProgressCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(vm.todaySteps.formatted()) steps")
                        .font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                    Text("out of \(vm.dailyGoal.formatted()) goal")
                        .font(.system(size: 12, weight: .light)).foregroundColor(.white.opacity(0.4))
                }
                Spacer()
                Text(vm.percentageText)
                    .font(.system(size: 28, weight: .bold, design: .rounded)).foregroundColor(.white)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.08)).frame(height: 8)
                    RoundedRectangle(cornerRadius: 6).fill(Color.white)
                        .frame(width: geo.size.width * vm.progress, height: 8)
                        .animation(.easeInOut(duration: 0.8), value: vm.progress)
                }
            }.frame(height: 8)

            HStack {
                Text("0")
                Spacer()
                Text("1,000")
                Spacer()
                Text("2,000")
            }
            .font(.system(size: 10, weight: .ultraLight))
            .foregroundColor(.white.opacity(0.25))
        }
        .padding(20).glassCard()
    }

    private var monthName: String { let f = DateFormatter(); f.dateFormat = "MMMM"; return f.string(from: Date()) }
    private var currentYear: Int { Calendar.current.component(.year, from: Date()) }
    private var dayOfMonth: Int { Calendar.current.component(.day, from: Date()) }
    private func compact(_ n: Int) -> String {
        if n >= 1_000_000 { return String(format: "%.1fM", Double(n)/1_000_000) }
        if n >= 1_000     { return String(format: "%.1fK", Double(n)/1_000) }
        return "\(n)"
    }
}
