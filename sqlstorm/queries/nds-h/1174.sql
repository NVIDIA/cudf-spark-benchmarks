WITH SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        AVG(ps.ps_availqty) AS avg_avail_qty,
        COUNT(DISTINCT p.p_partkey) AS total_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_custkey,
        ROW_NUMBER() OVER(PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
CustomerSpend AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spend
    FROM 
        customer c
    JOIN 
        RecentOrders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        cs.total_spend
    FROM 
        CustomerSpend cs
    JOIN 
        customer c ON cs.c_custkey = c.c_custkey
    WHERE 
        cs.total_spend > 1000
)
SELECT 
    r.r_name,
    COUNT(DISTINCT hvc.c_custkey) AS high_value_customers_count,
    AVG(sp.total_supply_cost) AS average_supplier_costs,
    MAX(sp.avg_avail_qty) AS max_avg_availability
FROM 
    region r 
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierPerformance sp ON s.s_suppkey = sp.s_suppkey
LEFT JOIN 
    HighValueCustomers hvc ON n.n_nationkey = hvc.c_custkey
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT hvc.c_custkey) > 0 OR AVG(sp.total_supply_cost) > 5000
ORDER BY 
    r.r_name;