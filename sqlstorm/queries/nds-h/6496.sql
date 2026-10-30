WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
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
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        c.c_nationkey
),
NationSales AS (
    SELECT 
        n.n_name,
        ts.total_sales
    FROM 
        nation n
    JOIN 
        TotalSales ts ON n.n_nationkey = ts.c_nationkey
)
SELECT 
    rs.s_name,
    ns.n_name,
    rs.total_supply_cost,
    ns.total_sales,
    (rs.total_supply_cost / NULLIF(ns.total_sales, 0)) AS cost_to_sales_ratio
FROM 
    RankedSuppliers rs
JOIN 
    NationSales ns ON rs.rank = 1 AND ns.total_sales > 0
ORDER BY 
    cost_to_sales_ratio DESC
LIMIT 10;