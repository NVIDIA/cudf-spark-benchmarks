WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS distinct_parts_supplied
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_orders_value,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(CASE WHEN o.o_orderstatus = 'F' THEN o.o_totalprice ELSE 0 END) AS total_fulfilled_orders_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
Ranking AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        cs.total_orders_value,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_orders_value DESC) AS sales_rank,
        RANK() OVER (ORDER BY s.total_available_qty DESC) AS supply_rank
    FROM SupplierStats s
    JOIN CustomerStats cs ON s.s_suppkey = cs.c_custkey
)
SELECT 
    r.s_suppkey,
    r.s_name,
    r.total_orders_value,
    r.total_orders,
    r.sales_rank,
    r.supply_rank
FROM Ranking r
WHERE r.sales_rank <= 10 OR r.supply_rank <= 10
ORDER BY r.sales_rank, r.supply_rank;
