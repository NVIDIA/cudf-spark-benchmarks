
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank_by_acctbal
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
), FilteredLineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_quantity,
        l.l_extendedprice,
        COALESCE(NULLIF(l.l_discount, 0), 0.01) AS effective_discount,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber) AS item_number
    FROM lineitem l
    WHERE l.l_shipdate < DATE '1998-10-01'
), CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        SUM(li.l_extendedprice * (1 - li.effective_discount)) AS net_total
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN FilteredLineItems li ON o.o_orderkey = li.l_orderkey
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
)
SELECT 
    r.r_name,
    COUNT(DISTINCT co.o_orderkey) AS total_orders,
    SUM(co.net_total) AS total_revenue,
    MAX(co.o_orderdate) AS latest_order_date,
    (SELECT AVG(v.total_revenue) FROM (
        SELECT SUM(co2.net_total) AS total_revenue
        FROM CustomerOrders co2
        JOIN nation n ON co2.c_custkey = n.n_nationkey
        WHERE n.n_regionkey IS NOT NULL 
        GROUP BY n.n_name
    ) v) AS avg_region_revenue
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN CustomerOrders co ON n.n_nationkey = co.c_custkey
WHERE EXISTS (
    SELECT 1
    FROM RankedSuppliers rs
    WHERE rs.rank_by_acctbal <= 3 AND rs.s_suppkey = co.o_orderkey
)
GROUP BY r.r_name
HAVING SUM(co.net_total) > (SELECT AVG(total_revenue) FROM (
    SELECT SUM(co3.net_total) AS total_revenue 
    FROM CustomerOrders co3 
    GROUP BY co3.c_name
) t)
ORDER BY total_orders DESC, total_revenue DESC;
