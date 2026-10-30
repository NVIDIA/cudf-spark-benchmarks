WITH PartSupplier AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_type, 
        p.p_size, 
        s.s_name AS supplier_name, 
        ps.ps_availqty, 
        ps.ps_supplycost, 
        ps.ps_comment
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_mktsegment, 
        o.o_orderkey, 
        o.o_orderstatus, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-10-01'
    GROUP BY 
        c.c_custkey, c.c_name, c.c_mktsegment, o.o_orderkey, o.o_orderstatus, o.o_orderdate
),
FinalBenchmark AS (
    SELECT 
        ps.p_name, 
        ps.p_mfgr, 
        SUM(co.total_spent) AS total_revenue, 
        COUNT(DISTINCT co.c_custkey) AS unique_customers
    FROM 
        PartSupplier ps
    JOIN 
        CustomerOrders co ON ps.supplier_name = co.c_name
    WHERE 
        ps.ps_supplycost < 50.00
    GROUP BY 
        ps.p_name, ps.p_mfgr
    ORDER BY 
        total_revenue DESC
)
SELECT 
    p_name, 
    p_mfgr, 
    total_revenue, 
    unique_customers
FROM 
    FinalBenchmark
LIMIT 10;