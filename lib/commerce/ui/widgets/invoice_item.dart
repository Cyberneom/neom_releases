import 'package:flutter/material.dart';

import 'package:neom_commons/core/utils/app_utilities.dart';
import '../../domain/models/invoice.dart';

class InvoiceItem extends StatelessWidget {

  final Invoice invoice;
  const InvoiceItem({
    super.key,
    required this.invoice,
  });

  @override
  Widget build(BuildContext context) {


    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2.0,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Receipt Id ${invoice.id}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    '${invoice.payment!.price.currency.name}${invoice.payment!.finalAmount}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppUtilities.dateFormat(invoice.createdTime),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    'Duration: ${invoice.orderId}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const Divider(color: Colors.black),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Services type: ',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        TextSpan(
                          text: invoice.payment!.type.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge!
                              .copyWith(color: Theme.of(context).primaryColor),
                        )
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      invoice.payment!.status.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge!
                          .copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
              ListTile(
                leading: CircleAvatar(
                  radius: 25,
                  backgroundImage: NetworkImage(invoice.toUser.photoUrl),
                ),
                title: Text(
                  invoice.toUser.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                subtitle: Text(invoice.description),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
