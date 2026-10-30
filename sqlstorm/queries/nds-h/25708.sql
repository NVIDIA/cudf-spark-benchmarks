
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        RANK() OVER (ORDER BY COUNT(DISTINCT ps.ps_partkey) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal
    FROM 
        RankedSuppliers s
    WHERE 
        s.supplier_rank <= 5
),
TotalSales AS (
    SELECT 
        l.l_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate > '1996-01-01'
    GROUP BY 
        l.l_suppkey
)
SELECT 
    ts.s_suppkey,
    ts.s_name,
    ts.s_acctbal,
    COALESCE(t.total_revenue, 0) AS total_revenue,
    CONCAT('Supplier: ', ts.s_name, ', Active since previous year') AS supplier_info,
    LEFT(ts.s_name, 10) AS short_name,
    ROUND(ts.s_acctbal / 1000.0, 2) AS account_balance_k
FROM 
    TopSuppliers ts
LEFT JOIN 
    TotalSales t ON ts.s_suppkey = t.l_suppkey
ORDER BY 
    total_revenue DESC, ts.s_name ASC;
