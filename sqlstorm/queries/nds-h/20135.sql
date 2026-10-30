
WITH RankedSupp AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS bal_rank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
), OrderSummary AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_discount * l.l_extendedprice) AS total_discounted_price 
    FROM 
        orders o 
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey 
    GROUP BY 
        o.o_orderkey
), HighValueOrders AS (
    SELECT 
        os.o_orderkey 
    FROM 
        OrderSummary os 
    WHERE 
        os.total_discounted_price > (
            SELECT AVG(total_discounted_price) 
            FROM OrderSummary
        )
), SupPart AS (
    SELECT 
        p.p_partkey, 
        ps.ps_availqty, 
        ps.ps_supplycost 
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey 
    WHERE 
        p.p_retailprice BETWEEN 10.00 AND 500.00
), FilteredSup AS (
    SELECT 
        rs.s_suppkey, 
        rs.s_name 
    FROM 
        RankedSupp rs 
    WHERE 
        rs.bal_rank <= 5
)
SELECT 
    f.s_name AS supplier_name, 
    COUNT(DISTINCT hvo.o_orderkey) AS order_count, 
    SUM(sp.ps_availqty * sp.ps_supplycost) AS total_supply_cost 
FROM 
    FilteredSup f 
LEFT JOIN 
    lineitem l ON l.l_suppkey = f.s_suppkey 
LEFT JOIN 
    HighValueOrders hvo ON l.l_orderkey = hvo.o_orderkey 
LEFT JOIN 
    SupPart sp ON l.l_partkey = sp.p_partkey 
WHERE 
    (f.s_suppkey IS NOT NULL OR l.l_quantity IS NULL) 
    AND (sp.ps_supplycost IS NOT NULL OR l.l_discount = 0) 
GROUP BY 
    f.s_name 
HAVING 
    COUNT(DISTINCT hvo.o_orderkey) > 1 
ORDER BY 
    total_supply_cost DESC 
LIMIT 10;
