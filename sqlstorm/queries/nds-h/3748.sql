WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
),
TotalSales AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    JOIN 
        RankedOrders r ON l.l_orderkey = r.o_orderkey
    WHERE 
        l.l_shipdate >= DATE '1996-01-01'
    GROUP BY 
        l.l_partkey
),
SuppliersWithSales AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
Combined AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(t.total_sales, 0) AS total_sales,
        COALESCE(sws.supplier_cost, 0) AS supplier_cost
    FROM 
        part p
    LEFT JOIN 
        TotalSales t ON p.p_partkey = t.l_partkey
    LEFT JOIN 
        SuppliersWithSales sws ON p.p_partkey = sws.ps_partkey
)
SELECT 
    c.p_partkey,
    c.p_name,
    c.total_sales,
    c.supplier_cost,
    CASE 
        WHEN c.total_sales > c.supplier_cost THEN 'Profitable'
        WHEN c.total_sales = c.supplier_cost THEN 'Break Even'
        ELSE 'Not Profitable' 
    END AS profitability,
    DENSE_RANK() OVER (ORDER BY c.total_sales DESC) AS sales_rank
FROM 
    Combined c
WHERE 
    c.total_sales IS NOT NULL
ORDER BY 
    c.total_sales DESC
LIMIT 10;