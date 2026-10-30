WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_availqty,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        RankedSuppliers r
    JOIN 
        supplier s ON r.s_suppkey = s.s_suppkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        r.rn = 1
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrdersWithDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        SUM(l.l_tax) AS total_tax,
        AVG(l.l_quantity) AS avg_quantity,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name
),
FinalReport AS (
    SELECT 
        owd.o_orderkey,
        owd.o_orderdate,
        owd.total_value,
        owd.total_tax,
        ts.total_availqty,
        ts.total_supplycost,
        CASE 
            WHEN owd.total_value > 1000 THEN 'High Value'
            WHEN owd.total_value IS NULL THEN 'No Value'
            ELSE 'Standard Value'
        END AS order_status,
        RANK() OVER (ORDER BY owd.total_value DESC) AS rank_value
    FROM 
        OrdersWithDetails owd
    LEFT JOIN 
        TopSuppliers ts ON owd.o_orderkey = ts.s_suppkey
)
SELECT 
    fr.o_orderkey,
    fr.o_orderdate,
    fr.total_value,
    fr.total_tax,
    fr.total_availqty,
    fr.total_supplycost,
    fr.order_status,
    fr.rank_value
FROM 
    FinalReport fr
WHERE 
    fr.order_status != 'No Value' 
ORDER BY 
    fr.rank_value DESC 
LIMIT 50;
