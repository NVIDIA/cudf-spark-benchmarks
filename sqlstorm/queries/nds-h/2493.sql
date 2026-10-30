WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, c.c_name, o.o_orderdate, o.o_orderstatus
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
FilteredRegions AS (
    SELECT 
        n.n_nationkey,
        r.r_name,
        SUM(s.s_acctbal) AS total_account_balance
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
    GROUP BY n.n_nationkey, r.r_name
    HAVING SUM(s.s_acctbal) > 1000
)
SELECT 
    ro.o_orderkey,
    ro.c_name,
    ro.total_revenue,
    sd.s_name AS top_supplier,
    fr.r_name AS region_name,
    fr.total_account_balance
FROM RankedOrders ro
LEFT JOIN SupplierDetails sd ON ro.o_orderkey = sd.s_suppkey
JOIN FilteredRegions fr ON sd.total_supply_cost > (SELECT AVG(total_supply_cost) FROM SupplierDetails)
WHERE ro.order_rank <= 10
ORDER BY ro.total_revenue DESC;
