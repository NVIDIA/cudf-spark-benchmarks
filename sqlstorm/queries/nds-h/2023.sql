WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-02-01'
),
TopSuppliers AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_suppkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000000
),
NationRegionalSales AS (
    SELECT 
        n.n_name,
        SUM(o.o_totalprice) AS total_sales
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_name
),
FinalReport AS (
    SELECT 
        r.r_name AS region,
        n.n_name AS nation,
        COALESCE(ns.total_sales, 0) AS nation_sales,
        ts.total_supply_cost
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        NationRegionalSales ns ON n.n_name = ns.n_name
    LEFT JOIN 
        TopSuppliers ts ON n.n_nationkey = ts.ps_suppkey
)
SELECT 
    region,
    nation,
    nation_sales,
    total_supply_cost,
    CASE 
        WHEN nation_sales > 0 AND total_supply_cost IS NOT NULL THEN nation_sales / total_supply_cost 
        ELSE NULL 
    END AS sales_to_supply_cost_ratio
FROM 
    FinalReport
WHERE 
    total_supply_cost IS NOT NULL
ORDER BY 
    sales_to_supply_cost_ratio DESC
LIMIT 10;