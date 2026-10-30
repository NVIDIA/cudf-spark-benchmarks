
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_container,
        ps.ps_availqty,
        ps.ps_supplycost,
        (p.p_retailprice - ps.ps_supplycost) AS profit_margin
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        (p.p_name LIKE '%steel%' OR p.p_name LIKE '%plastic%') 
        AND ps.ps_availqty > 100
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' 
        AND o.o_orderdate < '1998-01-01'
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey
),
FinalOutput AS (
    SELECT 
        n.n_name AS region_name,
        s.s_name AS supplier_name,
        hp.p_name AS part_name,
        hp.profit_margin,
        co.total_spent
    FROM 
        RankedSuppliers r
    JOIN 
        supplier s ON r.s_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        HighValueParts hp ON s.s_suppkey = hp.p_partkey
    JOIN 
        CustomerOrders co ON s.s_nationkey = co.c_custkey 
    WHERE 
        r.rnk <= 3
)
SELECT 
    fo.region_name,
    fo.supplier_name,
    fo.part_name,
    fo.profit_margin,
    SUM(fo.total_spent) AS total_customer_spending
FROM 
    FinalOutput fo
GROUP BY 
    fo.region_name, fo.supplier_name, fo.part_name, fo.profit_margin
ORDER BY 
    total_customer_spending DESC;
