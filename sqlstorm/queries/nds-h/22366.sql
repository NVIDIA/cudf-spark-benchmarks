WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_retailprice, 
        ROW_NUMBER() OVER(PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS brand_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL 
        AND p.p_size > 10
), 
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(s.s_acctbal) AS avg_supply_acctbal
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
), 
HighValueOrders AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus IN ('O', 'F')
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 20000
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_brand, 
    p.p_retailprice, 
    COALESCE(sa.total_availqty, 0) AS available_quantity,
    CASE 
        WHEN sa.avg_supply_acctbal IS NOT NULL 
        THEN sa.avg_supply_acctbal 
        ELSE (SELECT AVG(s.s_acctbal) FROM supplier s WHERE s.s_nationkey IS NOT NULL)
    END AS average_supplier_acctbal,
    ho.total_value AS order_total_value,
    RANK() OVER (ORDER BY p.p_retailprice DESC) AS retail_rank
FROM 
    RankedParts p
LEFT JOIN 
    SupplierAvailability sa ON p.p_partkey = sa.ps_partkey
LEFT JOIN 
    HighValueOrders ho ON ho.o_orderkey = (SELECT MAX(o.o_orderkey) FROM orders o WHERE o.o_orderkey <= (SELECT MAX(o2.o_orderkey) FROM orders o2 WHERE o2.o_orderstatus = 'F'))
WHERE 
    p.brand_rank <= 5 
    OR EXISTS (SELECT 1 FROM lineitem l WHERE l.l_partkey = p.p_partkey AND l.l_returnflag = 'R')
ORDER BY 
    p.p_brand, retail_rank;
