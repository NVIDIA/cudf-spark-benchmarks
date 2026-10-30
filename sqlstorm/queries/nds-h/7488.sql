WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'F'
),
RecentSupplierOrders AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        s.s_name,
        s.s_acctbal,
        r.r_name AS supplier_region
    FROM lineitem l
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE l.l_shipdate >= '1996-01-01'
),
CombinedResults AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_name AS customer_name,
        ro.c_acctbal AS customer_acctbal,
        rso.l_orderkey AS line_orderkey,
        rso.l_quantity,
        rso.l_extendedprice,
        rso.l_discount,
        rso.s_name AS supplier_name,
        rso.s_acctbal AS supplier_acctbal,
        rso.supplier_region
    FROM RankedOrders ro
    LEFT JOIN RecentSupplierOrders rso ON ro.o_orderkey = rso.l_orderkey
    WHERE ro.order_rank <= 5
)
SELECT 
    supplier_region,
    COUNT(DISTINCT o_orderkey) AS total_orders,
    SUM(l_extendedprice) AS total_revenue,
    AVG(l_discount) AS average_discount,
    AVG(customer_acctbal) AS average_customer_balance
FROM CombinedResults
GROUP BY supplier_region
ORDER BY total_orders DESC, total_revenue DESC;