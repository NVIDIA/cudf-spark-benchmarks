WITH  SalesCTE AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS spend_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank_by_acctbal
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
), PartSupplierSales AS (
    SELECT 
        p.p_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
), HighValueSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(ps.total_sales, 0) AS total_sales,
        ps.total_sales / NULLIF(SUM(ps.total_sales) OVER (), 0) * 100 AS sales_percentage
    FROM 
        part p
    LEFT JOIN 
        PartSupplierSales ps ON p.p_partkey = ps.p_partkey
), SupplierCustomerQuantities AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        s.s_suppkey
    HAVING 
        COUNT(DISTINCT c.c_custkey) > 10
)
SELECT 
    r.r_name AS region_name,
    SUM(s.total_spent) AS total_spending,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    AVG(sub.total_available) AS avg_avail_qty
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    SalesCTE s ON c.c_custkey = s.c_custkey
LEFT JOIN 
    SupplierCustomerQuantities sub ON c.c_nationkey = sub.s_suppkey
WHERE 
    r.r_name LIKE 'N%'
GROUP BY 
    r.r_name
ORDER BY 
    total_spending DESC
LIMIT 10;
