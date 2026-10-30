
WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
NationRegion AS (
    SELECT n.n_nationkey, n.n_name, r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
FinalReport AS (
    SELECT 
        sd.s_suppkey, 
        sd.s_name, 
        nr.r_name AS region_name, 
        COUNT(DISTINCT co.c_custkey) AS unique_customers_served,
        SUM(co.total_order_value) AS total_revenue_generated,
        SUM(sd.total_supply_cost) AS total_cost_of_supplies
    FROM SupplierDetails sd
    JOIN NationRegion nr ON sd.s_nationkey = nr.n_nationkey
    LEFT JOIN CustomerOrders co ON sd.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (
            SELECT l.l_partkey 
            FROM lineitem l 
            JOIN orders o ON l.l_orderkey = o.o_orderkey
            WHERE o.o_orderstatus = 'O'
        )
        LIMIT 1
    )
    GROUP BY sd.s_suppkey, sd.s_name, nr.r_name
    HAVING SUM(co.total_order_value) > 100000
)
SELECT 
    s_name, 
    region_name, 
    unique_customers_served, 
    total_revenue_generated, 
    total_cost_of_supplies
FROM FinalReport
ORDER BY total_revenue_generated DESC;
