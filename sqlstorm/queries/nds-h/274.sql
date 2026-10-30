WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        AVG(s.s_acctbal) AS avg_acct_balance
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_orderkey) AS number_of_items,
        RANK() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= cast('1998-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        o.o_orderkey, o.o_custkey
)
SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    ss.s_name AS supplier_name,
    ss.total_available_qty AS supplier_available_qty,
    ss.total_supply_value AS supplier_total_value,
    ro.total_order_value AS recent_order_value,
    ro.number_of_items AS items_in_recent_order
FROM 
    SupplierStats ss
LEFT OUTER JOIN 
    supplier s ON ss.s_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    RecentOrders ro ON s.s_suppkey = ro.o_custkey
WHERE 
    ss.avg_acct_balance IS NOT NULL
    AND (ss.total_available_qty > 0 OR ro.total_order_value IS NOT NULL)
ORDER BY 
    ss.total_supply_value DESC, 
    ro.total_order_value DESC NULLS LAST
LIMIT 100;