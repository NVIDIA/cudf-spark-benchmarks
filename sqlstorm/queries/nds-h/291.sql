
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= (CAST('1998-10-01' AS DATE) - INTERVAL '1 year')
),
SupplierCosts AS (
    SELECT 
        ps.ps_partkey, 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_suppkey, s.s_name
),
FilteredParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        COALESCE(SC.total_supplycost, 0) AS total_supplycost
    FROM 
        part p
    LEFT JOIN 
        SupplierCosts SC ON p.p_partkey = SC.ps_partkey
    WHERE 
        p.p_retailprice > 50.00
),
HighValueOrders AS (
    SELECT 
        r.o_orderkey, 
        r.o_orderdate, 
        r.c_name AS customer_name,
        p.p_partkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_value
    FROM 
        RankedOrders r
    JOIN 
        lineitem li ON r.o_orderkey = li.l_orderkey
    JOIN 
        FilteredParts p ON li.l_partkey = p.p_partkey
    GROUP BY 
        r.o_orderkey, r.o_orderdate, r.c_name, p.p_partkey
    HAVING 
        SUM(li.l_extendedprice * (1 - li.l_discount)) > 2000
)
SELECT 
    h.o_orderkey, 
    h.o_orderdate, 
    h.customer_name, 
    p.p_name,
    p.total_supplycost,
    CASE 
        WHEN h.total_value IS NULL THEN 'No Value'
        ELSE CAST(h.total_value AS STRING)
    END AS order_value_text
FROM 
    HighValueOrders h
JOIN 
    FilteredParts p ON h.p_partkey = p.p_partkey
ORDER BY 
    h.o_orderdate DESC, 
    h.total_value DESC;
