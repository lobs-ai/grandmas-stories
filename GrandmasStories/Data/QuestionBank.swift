import Foundation

// MARK: - QuestionCategory

struct QuestionCategory: Identifiable {
    let id: String
    let name: String
    let icon: String  // SF Symbol name
    let questions: [String]
}

// MARK: - QuestionBank

enum QuestionBank {
    static let categories: [QuestionCategory] = [
        QuestionCategory(
            id: "childhood",
            name: "Stories from my childhood",
            icon: "figure.play",
            questions: [
                "What is your earliest memory?",
                "What games did you play as a child?",
                "Tell us about your childhood home.",
                "Who was your best friend growing up and what did you do together?",
                "What was your favorite thing to do during summer as a kid?",
                "Did you have any pets growing up? Tell us about them.",
                "What was school like for you as a child?",
                "What did you want to be when you grew up?",
                "What family vacations or trips do you remember most fondly?"
            ]
        ),
        QuestionCategory(
            id: "children",
            name: "When my children were young",
            icon: "figure.and.child.holdinghands",
            questions: [
                "What is your favorite memory of when your children were small?",
                "What was the funniest thing one of your children ever said or did?",
                "What was bedtime like in your house?",
                "What activities or hobbies did your children love?",
                "What was the hardest part of raising children?",
                "What is something you taught your children that you're proud of?",
                "Tell us about a family tradition you started when your kids were young.",
                "What was a typical day like when your children were growing up?",
                "What did your children teach you?"
            ]
        ),
        QuestionCategory(
            id: "spouse",
            name: "Stories about my spouse",
            icon: "heart.fill",
            questions: [
                "How did you and your spouse meet?",
                "What was your first date like?",
                "What made you know they were the one?",
                "Tell us about your wedding day.",
                "What is your favorite memory of the two of you together?",
                "What did your spouse do that always made you smile?",
                "What is something your spouse was really good at?",
                "How did your spouse handle a difficult time in your lives?",
                "What would you want your family to know about your spouse?"
            ]
        ),
        QuestionCategory(
            id: "parents",
            name: "Stories about my parents",
            icon: "person.2.fill",
            questions: [
                "Tell us about your mother — what was she like?",
                "Tell us about your father — what was he like?",
                "What is a lesson your parents taught you that you still carry with you?",
                "What did your family do together on weekends?",
                "What is your favorite memory of your mother?",
                "What is your favorite memory of your father?",
                "What did your parents do for a living?",
                "What was your parents' love story?",
                "How did your parents shape who you became?"
            ]
        ),
        QuestionCategory(
            id: "favorites",
            name: "My favorite things",
            icon: "star.fill",
            questions: [
                "What is your all-time favorite meal?",
                "What book, movie, or song means the most to you?",
                "What is your favorite season and why?",
                "What hobbies have you loved most throughout your life?",
                "What is your favorite place you've ever visited?",
                "Who is your favorite person to spend time with and why?",
                "What is something small that brings you great joy?",
                "What has been your favorite decade of your life so far?",
                "What is a favorite family meal or recipe?"
            ]
        ),
        QuestionCategory(
            id: "holidays",
            name: "Holidays and traditions",
            icon: "gift.fill",
            questions: [
                "What did your family do to celebrate the holidays when you were growing up?",
                "What is your favorite holiday tradition?",
                "Tell us about a memorable Thanksgiving or Christmas.",
                "What special foods were always part of your holidays?",
                "How did you celebrate birthdays in your family?",
                "Did you have any unique family traditions that others might find unusual?",
                "What holiday memory makes you laugh the most?",
                "How have your family traditions changed over the years?",
                "What tradition do you hope your family carries on?"
            ]
        ),
        QuestionCategory(
            id: "lessons",
            name: "Life lessons I've learned",
            icon: "lightbulb.fill",
            questions: [
                "What is the most important lesson life has taught you?",
                "What advice would you give your younger self?",
                "What is something you wish you had done differently?",
                "What are you most proud of in your life?",
                "What does family mean to you?",
                "What has been the biggest challenge you've overcome?",
                "What do you believe is the secret to a happy life?",
                "Who has had the greatest influence on who you are?",
                "What values have guided your life?"
            ]
        ),
        QuestionCategory(
            id: "school",
            name: "My school years",
            icon: "graduationcap.fill",
            questions: [
                "What was your favorite subject in school?",
                "Who was your favorite teacher and why?",
                "What did you do after school?",
                "Tell us about your best friend from school.",
                "What was the most memorable thing that happened in school?",
                "Did you play any sports or join any clubs?",
                "What did a typical school day look like for you?",
                "What were lunches like at your school?",
                "What is something you learned in school that has stayed with you?"
            ]
        ),
        QuestionCategory(
            id: "friends",
            name: "Friends I'll never forget",
            icon: "person.3.fill",
            questions: [
                "Tell us about your best friend — how did you meet?",
                "What is your favorite memory with a close friend?",
                "Has a friend ever helped you through a really hard time? Tell us about it.",
                "Tell us about someone from your past you still think about.",
                "What made a particular friendship so special?",
                "Did you ever lose touch with a good friend? What happened?",
                "Is there a friend who always made you laugh? Tell us about them.",
                "What do you look for in a good friend?",
                "Who is the most interesting person you've ever been friends with?"
            ]
        ),
        QuestionCategory(
            id: "places",
            name: "Places I've lived",
            icon: "house.fill",
            questions: [
                "What is your favorite home you've ever lived in?",
                "Tell us about the neighborhood where you grew up.",
                "Have you ever moved somewhere new and had to start over? How was that?",
                "What is your favorite city or town you've ever lived in?",
                "What was special about the community where you raised your family?",
                "Tell us about a place you lived that was very different from where you grew up.",
                "What do you miss about a place you used to live?",
                "What does home mean to you?",
                "If you could live anywhere, where would it be and why?"
            ]
        ),
        QuestionCategory(
            id: "food",
            name: "Food and cooking memories",
            icon: "fork.knife",
            questions: [
                "What is your all-time favorite recipe?",
                "Who taught you to cook?",
                "What smell from the kitchen takes you back to your childhood?",
                "What dish did you make that your family loved most?",
                "Tell us about a meal you'll never forget.",
                "What is a family recipe you hope gets passed down?",
                "Was there a food you hated as a child but love now?",
                "What did your mother or grandmother make that you've tried to recreate?",
                "Tell us about a cooking disaster that makes you laugh now."
            ]
        ),
        QuestionCategory(
            id: "funny",
            name: "Funny moments",
            icon: "face.smiling.fill",
            questions: [
                "What is the funniest thing that has ever happened to you?",
                "Tell us about a time you laughed so hard you cried.",
                "What is the most embarrassing thing that happened to you?",
                "Tell us about a prank you played or had played on you.",
                "What is the funniest thing one of your children or grandchildren ever did?",
                "Has anything funny ever happened at a family gathering?",
                "Tell us about a time something went completely wrong but became a great story.",
                "What is an inside joke in your family?",
                "Who in your family always made everyone laugh?"
            ]
        )
    ]
}
