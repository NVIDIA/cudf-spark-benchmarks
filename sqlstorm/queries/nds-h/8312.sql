WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        n.n_name AS nation_name, 
        RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), FilteredParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice
    FROM 
        part p
    WHERE 
        p.p_retailprice > 100.00
), OrdersDetails AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= '1997-01-01' AND 
        l.l_shipdate < '1998-01-01'
    GROUP BY 
        o.o_orderkey, 
        o.o_orderdate
), SupplierSales AS (
    SELECT 
        rs.nation_name, 
        p.p_name, 
        SUM(ld.total_sales) AS total_sales_by_part
    FROM 
        RankedSuppliers rs
    JOIN 
        partsupp ps ON rs.s_suppkey = ps.ps_suppkey
    JOIN 
        FilteredParts p ON ps.ps_partkey = p.p_partkey
    JOIN 
        OrdersDetails ld ON p.p_partkey = ld.o_orderkey
    GROUP BY 
        rs.nation_name, 
        p.p_name
)
SELECT 
    ss.nation_name, 
    ss.p_name, 
    ss.total_sales_by_part
FROM 
    SupplierSales ss
WHERE 
    ss.total_sales_by_part > 5000.00
ORDER BY 
    ss.nation_name, 
    ss.total_sales_by_part DESC;