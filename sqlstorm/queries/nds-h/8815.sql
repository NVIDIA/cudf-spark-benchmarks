
WITH RankedCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_acctbal, 
        COUNT(o.o_orderkey) AS order_count,
        RANK() OVER (ORDER BY COUNT(o.o_orderkey) DESC) AS rank_count
    FROM 
        customer c 
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey 
    WHERE 
        c.c_acctbal > 0 
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
),
HighValueParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM 
        part p 
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey 
    GROUP BY 
        p.p_partkey, p.p_name 
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
LineItemAnalysis AS (
    SELECT 
        l.l_orderkey, 
        l.l_partkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS value_after_discount,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        lineitem l 
    GROUP BY 
        l.l_orderkey, l.l_partkey 
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 500
)
SELECT 
    rc.c_name, 
    rc.order_count, 
    hvp.p_name, 
    hvp.total_value, 
    lia.avg_quantity
FROM 
    RankedCustomers rc 
JOIN 
    orders o ON rc.c_custkey = o.o_custkey 
JOIN 
    LineItemAnalysis lia ON o.o_orderkey = lia.l_orderkey 
JOIN 
    HighValueParts hvp ON lia.l_partkey = hvp.p_partkey 
WHERE 
    rc.rank_count <= 10 
ORDER BY 
    rc.order_count DESC, 
    hvp.total_value DESC;
