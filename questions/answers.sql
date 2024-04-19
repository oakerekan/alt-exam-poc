                    --2a--
-- product_id, product_name, num_times_in_successful_orders.

-- in solving this particular problem, you want to join the orders table on the line item table, then join that on the product table.
-- the logic behind it is to get the successful order and then check for the item in those orders and how many times they appear. 
--existence of each unique instance on a sucessful order_id id += 1
select p.id as product_id, p.name as product_name, count(*) as num_times_in_successful_orders
from alt_school.orders o
inner join alt_school.line_items l
  on o.order_id = l.order_id  --join the orders and line items table when they have the order_id being the same.
inner join alt_school.products p
  on l.item_id = p.id --join the products and line items table when they have the item_id and id being the same.
  where o.status = 'success'  -- filter for successful orders
group by 1, 2  -- group by product_id and name only
order by 3 desc -- arrange by the number of successful order from the high to low
limit 1; --return the first item

--ans 7, apple airpods pro, 735


-- total spend by customer_id and location not minding the currency

with item_id_quant as (
   select event_data ->> 'item_id' as item_id, event_data ->> 'quantity' as quantity, customer_id
   from alt_school.events
   where event_data ->> 'event_type' = 'add_to_cart' 
), --item_id_quant cte returns the item_id, quantity and customer_id from events table where the event_type is add_to_cart.
item_id_remove as (
   select event_data ->> 'item_id' as item_id, customer_id
   from alt_school.events
   where event_data ->> 'event_type' = 'remove_from_cart'
), --item_id_remove cte returns the item_id and customer_id from events table where the event_type is remove from cart.
order_id_cust as (
   select event_data ->> 'order_id' as order_id,customer_id 
   from alt_school.events
   where event_data ->> 'event_type' = 'checkout' and event_data ->> 'status' = 'success')
   -- the order_id_cust returns the order_id and customer_id from events table where event type is checkout and status is success
select it.customer_id customer_id, c.location location, sum(it.quantity::int * p.price) as total_spend
from order_id_cust oc
inner join item_id_quant it on oc.customer_id = it.customer_id --join the order_id_cust and item_id_quant table when they have the customer_id being the same.
left join item_id_remove ir on it.customer_id = ir.customer_id and it.item_id = ir.item_id --left join the item_id_remove and item_id_quant table where customer_id is the same and ite id is the same
inner join products p on it.item_id::int = p.id --join the product and item_id_quant table when they have the item_id and id being the same.
inner join customers c on it.customer_id = c.customer_id --join the item_id_quant table and customer table where the customer_id is the same
where ir.item_id is null -- exclude items that are removed from the cart
group by 1,2 --groupby the customer_id and location for the aggregate function
order by 3 desc --sort in descending order based on total spend
limit 5; -- return the top 5 customer_id

                        -- 2b 



--location and checkout count

select c.location as location, count(*) as checkout_count -- returns the location and the count of order from that location
from alt_school.events e
inner join alt_school.customers c 
  on c.customer_id = e.customer_id -- join the customer table on event where they have same customer_id
where e.event_data ->> 'event_type' = 'checkout'  -- filter for checkout only
group by c.location --group by the location because you used an aggregate function in your query.
order by checkout_count desc --sort from high to low
limit 1; --return the first result
--according to the logic, the checkout does not have to be successful to count

-- ans korea, 46



-- customer_id and number of abandoment

-- customer_id and num_events aside visit and checkout
select ca.customer_id, count(*) as num_events
from 
(select customer_id, event_id
from alt_school.events e1
where e1.event_data ->> 'event_type' = 'add_to_cart' -- this subquery return customer id and event_id where it was added to cart
except all 
(select customer_id, event_id
from alt_school.events e2
where e2.event_data ->> 'event_type' in ('checkout', 'remove_from_cart')
    ) --this subqueury returns customer_id and event_id that where check_out or removed
) as ca --ca intends to return the customer_id and events id that were added to cart but not checked out or removed!
inner join alt_school.events e on ca.customer_id = e.customer_id --join the ca and event table together on the same customer_id
inner join (
    select customer_id, max(event_timestamp) as latest_event_timestamp
    from alt_school.events
    group by customer_id
) as latest_events on ca.customer_id = latest_events.customer_id --returns the customer_id and max event time as table and joined with ca when the customer_id is the same
where e.event_data ->> 'event_type' != 'visit' --when the event_type is not visit and time_stamp is greater that latest.event_time stamp
    and e.event_timestamp < latest_events.latest_event_timestamp
group by ca.customer_id --groupby customer_id
order by 2 desc; --sort in descending order
--



--average number of visit before checkout
select round(avg(visit_count),2) as average_visits
from (
  select customer_id, count(*) as visit_count
  from alt_school.events e
  where e.event_data ->> 'event_type' = 'visit'
  group by customer_id
) as visit_data --visit_data is a subquery which return the customer Id, and visit count from the event table when the event type is a visit. 
where customer_id in (
  select customer_id 
  from alt_school.events e
  where e.event_data ->> 'event_type' = 'checkout' and e.event_data ->> 'status' = 'success'
);
-- with the second subquery you intend to get a list of customer_id that ended in a check out and status is success
-- the block of code want to get the average visit count by taking the visit and check how many it take to get atleast a successful checkout on the average and round it to two decimal points.
-- ans 4.47

