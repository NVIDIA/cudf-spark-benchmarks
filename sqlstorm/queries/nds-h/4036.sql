
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '6 MONTH'
),
SupplierSummary AS (
    SELECT 
        s.s_nationkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_nationkey
),
TopNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COALESCE(ss.supplier_count, 0) AS supplier_count,
        COALESCE(ss.total_supply_cost, 0) AS total_supply_cost
    FROM 
        nation n
    LEFT JOIN 
        SupplierSummary ss ON n.n_nationkey = ss.s_nationkey
    WHERE 
        n.n_regionkey = (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'ASIA')
),
TotalSales AS (
    SELECT 
        c.c_nationkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_nationkey
)
SELECT 
    tn.n_name,
    tn.supplier_count,
    tn.total_supply_cost,
    COALESCE(ts.total_sales, 0) AS total_sales,
    ROUND(COALESCE(ts.total_sales, 0) / NULLIF(tn.total_supply_cost, 0), 2) AS sales_per_supply_cost
FROM 
    TopNations tn
LEFT JOIN 
    TotalSales ts ON tn.n_nationkey = ts.c_nationkey
WHERE 
    tn.supplier_count > 0
ORDER BY 
    sales_per_supply_cost DESC;
