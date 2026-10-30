WITH RecursiveSales AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1994-01-01' 
        AND o.o_orderdate < '1995-01-01'
    GROUP BY 
        o.o_orderkey
), 
TopSales AS (
    SELECT 
        rs.o_orderkey, 
        rs.total_sales
    FROM 
        RecursiveSales rs
    WHERE 
        rs.sales_rank <= 10
), 
SupplierCosts AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
    GROUP BY 
        ps.ps_partkey
), 
PartDetails AS (
    SELECT 
        p.p_partkey, 
        AVG(p.p_retailprice) AS avg_price
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 5 AND 15
    GROUP BY 
        p.p_partkey
) 
SELECT 
    t.o_orderkey, 
    COALESCE(s.total_supply_cost, 0) AS supply_cost, 
    COALESCE(p.avg_price, 0) AS avg_price,
    CASE 
        WHEN s.total_supply_cost IS NULL THEN 'No Supplier'
        ELSE 'Has Supplier'
    END AS supplier_status
FROM 
    TopSales t
LEFT JOIN 
    SupplierCosts s ON t.o_orderkey = s.ps_partkey
LEFT JOIN 
    PartDetails p ON s.ps_partkey = p.p_partkey
WHERE 
    (p.avg_price > 0 OR s.total_supply_cost IS NULL)
    OR (t.total_sales > 1000 AND p.avg_price IS NOT NULL)
ORDER BY 
    t.total_sales DESC, 
    supply_cost ASC;
