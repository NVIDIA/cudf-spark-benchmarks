
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_mktsegment,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'O'
), AggregatedSupplier AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey
), RecentLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_quantity,
        l.l_extendedprice,
        CASE 
            WHEN l.l_discount = 0 THEN 'No Discount'
            ELSE CONCAT('Discounted by ', l.l_discount * 100, '%')
        END AS discount_info,
        DENSE_RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_shipdate DESC) AS rank_ship_date
    FROM lineitem l
    WHERE l.l_shipdate >= CURRENT_DATE - INTERVAL '3 months'
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    r.c_mktsegment,
    COALESCE(a.total_supply_cost, 0) AS total_supply_cost,
    COALESCE(l.l_quantity, 0) AS total_quantity,
    MAX(l.discount_info) AS discount_info,
    CASE 
        WHEN r.o_totalprice > 10000 THEN 'High Value Order'
        ELSE 'Standard Order'
    END AS order_value_category
FROM RankedOrders r
LEFT JOIN AggregatedSupplier a ON r.o_orderkey = a.s_suppkey
LEFT JOIN RecentLineItems l ON r.o_orderkey = l.l_orderkey AND l.rank_ship_date = 1
WHERE r.rn <= 5
GROUP BY r.o_orderkey, r.o_orderdate, r.o_totalprice, r.c_mktsegment, a.total_supply_cost, l.l_quantity
ORDER BY r.o_totalprice DESC, r.o_orderdate ASC;
