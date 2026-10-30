WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
HighValueParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)

SELECT 
    p.p_name,
    p.p_brand,
    r.r_name AS region,
    COALESCE(cus.total_spent, 0) AS customer_total_spent,
    SUM(CASE 
            WHEN l.l_returnflag = 'Y' THEN l.l_extendedprice 
            ELSE 0 
        END) AS total_returned_amount,
    AVG(CASE 
            WHEN l.l_tax IS NULL THEN 0 
            ELSE l.l_tax 
        END) AS avg_tax,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    CustomerOrderSummary cus ON o.o_custkey = cus.c_custkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_retailprice BETWEEN 5 AND 100
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND EXISTS (SELECT 1 FROM HighValueParts hvp WHERE hvp.ps_partkey = p.p_partkey)
GROUP BY 
    p.p_name, p.p_brand, r.r_name, cus.total_spent
HAVING 
    SUM(l.l_quantity) > 50
ORDER BY 
    customer_total_spent DESC, p.p_name;