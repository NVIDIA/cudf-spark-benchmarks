WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
TopSuppliers AS (
    SELECT * FROM RankedSuppliers WHERE rank <= 3
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        p.p_name, 
        p.p_brand, 
        p.p_retailprice, 
        ps.ps_availqty * ps.ps_supplycost AS total_supply_value
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_suppkey IN (SELECT s_suppkey FROM TopSuppliers)
),
SalesSummary AS (
    SELECT 
        l.l_orderkey, 
        c.c_mktsegment, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS sales_value
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        l.l_orderkey, c.c_mktsegment
)
SELECT 
    sp.p_name, 
    sp.p_brand, 
    SUM(ss.sales_value) AS total_sales_value, 
    SUM(sp.total_supply_value) AS total_supply_value,
    SUM(ss.sales_value) - SUM(sp.total_supply_value) AS profit_margin
FROM 
    SupplierParts sp
JOIN 
    SalesSummary ss ON sp.ps_partkey = ss.l_orderkey
GROUP BY 
    sp.p_name, 
    sp.p_brand
ORDER BY 
    profit_margin DESC
LIMIT 10;