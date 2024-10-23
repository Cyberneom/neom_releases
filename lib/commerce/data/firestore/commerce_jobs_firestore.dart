import 'package:neom_commons/core/domain/model/subscription_plan.dart';
import 'package:neom_commons/core/utils/enums/subscription_level.dart';

import 'subscription_plan_firestore.dart';

class CommerceJobsFirestore {

  void insertSubscriptionPlans() async {
    SubscriptionPlanFirestore subscriptionPlanFirestore = SubscriptionPlanFirestore();

    // Lista de planes de suscripción con sus datos hardcodeados desde la imagen
    List<SubscriptionPlan> subscriptionPlans = [
      SubscriptionPlan(
        id: "artistPlan",
        name: "artistPlan",
        productId: "prod_QzVWA5ZJaxrk6D",
        priceId: "price_1Q7WVWHpVUHkmiYFhVeMVKfC",
        level: SubscriptionLevel.artist,
        imgUrl: "https://www.escritoresmxi.org/wp-content/uploads/2023/12/Plan-de-suscripcion-Inicial.jpeg",
        href: "https://www.escritoresmxi.org/libreriadigital/membresia-plan-artista/",
        isActive: true,
      ),
      SubscriptionPlan(
        id: "basicPlan",
        name: "basicPlan",
        productId: "prod_QvY34BvmkRiWa",
        priceId: "price_1Q8STHpVUHkmiYF4l8sTLxO",
        level: SubscriptionLevel.basic,
        imgUrl: "https://www.escritoresmxi.org/libreriadigital/membresia-plan-basico/",
        href: "https://www.escritoresmxi.org/libreriadigital/membresia-plan-basico/",
        isActive: true,
      ),
      SubscriptionPlan(
        id: "creatorPlan",
        name: "creatorPlan",
        productId: "prod_ROV2TQ55pxymGI",
        priceId: "price_1Q8U2SHpVUHkmiYFRBSJk6xc",
        level: SubscriptionLevel.creator,
        imgUrl: "https://www.escritoresmxi.org/wp-content/uploads/2024/09/Plan-Posicionate.jpg",
        href: "https://www.escritoresmxi.org/libreriadigital/membresia-plan-posicionate/",
        isActive: true,
      ),
      SubscriptionPlan(
        id: "premiumPlan",
        name: "premiumPlan",
        productId: "prod_Qzh8z4x5Nc9gd",
        priceId: "price_1Q7hkZHpVUHkmiYF6eDYloG",
        level: SubscriptionLevel.premium,
        imgUrl: 'https://www.escritoresmxi.org/wp-content/uploads/2023/12/Premium-cuadrado-imagen3.jpg',
        href: "https://www.escritoresmxi.org/libreriadigital/membresia-plan-premium/",
        isActive: true,
      ),
      SubscriptionPlan(
        id: "professionalPlan",
        name: "professionalPlan",
        productId: "prod_QzVc88mKouprWR",
        priceId: "price_1Q7WbJHpVUHkmiYFEzTYW8XH",
        level: SubscriptionLevel.professional,
        imgUrl: "https://www.escritoresmxi.org/wp-content/uploads/2023/12/Plan-de-suscripcion-Profesional.jpeg",
        href: "https://www.escritoresmxi.org/libreriadigital/membresia-plan-profesional/",
        isActive: true,
      ),
      SubscriptionPlan(
        id: "publishPlan",
        name: "publishPlan",
        productId: "prod_ROUjpm5bHLoWY",
        priceId: "price_1Q8TjKHpVUHkmiYFfDmz1GBw",
        level: SubscriptionLevel.publish,
        imgUrl: "https://www.escritoresmxi.org/wp-content/uploads/2024/09/Plan-Publicate.jpg",
        href: "https://www.escritoresmxi.org/libreriadigital/membresia-plan-publicate/",
        isActive: true,
      ),
    ];

    // Inserta cada uno de los planes
    for (var plan in subscriptionPlans) {
      await subscriptionPlanFirestore.insert(plan);
      print("Inserted plan with ID: ${plan.id}");
    }
  }

}