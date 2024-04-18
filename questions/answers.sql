                    --2a--
-- In Solving this particular problem, you want to join the orders table on the line item table, then join that on the product table.
-- The Logic behind it is to get the successful order and then check for the item in those orders and how many times they appear. 
--Existence of each unique instance on a sucessful order_id ID += 1
select p.id AS product_id, p.name AS product_name, Count(*) AS num_times_in_successful_orders
from alt_school.orders o
inner join alt_school.line_items l
  on o.order_id = l.order_id
inner join alt_school.products p
  on l.item_id = p.id
group by 1, 2  -- Group by product id and name only
having o.status = 'success'  -- Filter for successful orders
order by 3 desc
limit 1;

--Ans 7, Apple AirPods Pro, 735

                        -- 2b 

SELECT c.location AS location, COUNT(e.event_data ->> 'order_id') AS checkout_count
FROM alt_school.events e
INNER JOIN alt_school.customers c 
  ON c.customer_id = e.customer_id
WHERE e.event_data ->> 'status' = 'success'  -- Filter for successful orders only
GROUP BY c.location
ORDER BY checkout_count DESC
LIMIT 1;

-- Ans Korea, 17

-- Customer_id and num_events aside visit and checkout
SELECT ca.customer_id, COUNT(*) AS num_events
FROM 
(SELECT customer_id, event_id
FROM alt_school.events e1
WHERE e1.event_data ->> 'event_type' = 'add_to_cart'
EXCEPT ALL 
(SELECT customer_id, event_id
FROM alt_school.events e2
WHERE e2.event_data ->> 'event_type' IN ('checkout', 'remove_from_cart')
    )
) AS ca
INNER JOIN alt_school.events e ON ca.customer_id = e.customer_id
INNER JOIN (
    SELECT customer_id, MAX(event_timestamp) AS latest_event_timestamp
    FROM alt_school.events
    GROUP BY customer_id
) AS latest_events ON ca.customer_id = latest_events.customer_id
WHERE e.event_data ->> 'event_type' != 'visit'
    AND e.event_timestamp < latest_events.latest_event_timestamp
GROUP BY ca.customer_id;
--


--Average number of visit before checkout


SELECT round(AVG(visit_count),2) AS average_visits
FROM (
  SELECT customer_id, COUNT(*) AS visit_count
  FROM alt_school.events e
  WHERE e.event_data ->> 'event_type' = 'visit'
  GROUP BY customer_id
) AS visit_data
WHERE customer_id IN (
  SELECT customer_id 
  FROM alt_school.events e
  WHERE e.event_data ->> 'event_type' = 'checkout'
);

-- Ans 4.51