                    --2a--
-- in solving this particular problem, you want to join the orders table on the line item table, then join that on the product table.
-- the logic behind it is to get the successful order and then check for the item in those orders and how many times they appear. 
--existence of each unique instance on a sucessful order_id id += 1
select p.id as product_id, p.name as product_name, count(*) as num_times_in_successful_orders
from alt_school.orders o
inner join alt_school.line_items l
  on o.order_id = l.order_id
inner join alt_school.products p
  on l.item_id = p.id
group by 1, 2  -- group by product id and name only
having o.status = 'success'  -- filter for successful orders
order by 3 desc
limit 1;

--ans 7, apple airpods pro, 735

with item_id_quant as (
   select event_data ->> 'item_id' as item_id, event_data ->> 'quantity' as quantity, customer_id
   from alt_school.events
   where event_data ->> 'event_type' = 'add_to_cart'
),
item_id_remove as (
   select event_data ->> 'item_id' as item_id, customer_id
   from alt_school.events
   where event_data ->> 'event_type' = 'remove_from_cart'
),
order_id_cust as (
   select event_data ->> 'order_id' as order_id,
       customer_id from alt_school.events
		where event_data ->> 'event_type' = 'checkout' and event_data ->> 'status' = 'success')
select it.customer_id customer_id, c.location location, sum(it.quantity::int * p.price) as total_spend
from order_id_cust oc
inner join item_id_quant it on oc.customer_id = it.customer_id
left join item_id_remove ir on it.customer_id = ir.customer_id and it.item_id = ir.item_id
inner join products p on it.item_id::int = p.id
inner join customers c
on it.customer_id = c.customer_id
where ir.item_id is null -- exclude items that are removed from the cart
group by 1,2
order by 3 desc;


                        -- 2b 

select c.location as location, count(e.event_data ->> 'order_id') as checkout_count
from alt_school.events e
inner join alt_school.customers c 
  on c.customer_id = e.customer_id
where e.event_data ->> 'status' = 'success'  -- filter for successful orders only
group by c.location
order by checkout_count desc
limit 1;

-- ans korea, 17

-- customer_id and num_events aside visit and checkout
select ca.customer_id, count(*) as num_events
from 
(select customer_id, event_id
from alt_school.events e1
where e1.event_data ->> 'event_type' = 'add_to_cart'
except all 
(select customer_id, event_id
from alt_school.events e2
where e2.event_data ->> 'event_type' in ('checkout', 'remove_from_cart')
    )
) as ca
inner join alt_school.events e on ca.customer_id = e.customer_id
inner join (
    select customer_id, max(event_timestamp) as latest_event_timestamp
    from alt_school.events
    group by customer_id
) as latest_events on ca.customer_id = latest_events.customer_id
where e.event_data ->> 'event_type' != 'visit'
    and e.event_timestamp < latest_events.latest_event_timestamp
group by ca.customer_id;
--


--average number of visit before checkout


select round(avg(visit_count),2) as average_visits
from (
  select customer_id, count(*) as visit_count
  from alt_school.events e
  where e.event_data ->> 'event_type' = 'visit'
  group by customer_id
) as visit_data
where customer_id in (
  select customer_id 
  from alt_school.events e
  where e.event_data ->> 'event_type' = 'checkout'
);

-- ans 4.51

