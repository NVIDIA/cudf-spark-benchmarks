WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 100.00)
), 
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_availqty) > 5000
), 
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        DENSE_RANK() OVER (ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'P') 
        AND o.o_totalprice > (SELECT AVG(o_sub.o_totalprice) FROM orders o_sub)
), 
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), 
ComplexJoin AS (
    SELECT 
        p.p_name,
        s.s_name,
        COALESCE(l.l_discount, 0) AS discount,
        COALESCE(ROUND(l.l_extendedprice * (1 - l.l_discount), 2), 0) AS net_price
    FROM 
        RankedParts p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    LEFT JOIN 
        lineitem l ON l.l_partkey = p.p_partkey AND l.l_suppkey = s.s_suppkey
    WHERE 
        p.price_rank <= 3 AND s.s_suppkey IS NOT NULL
), 
FinalResults AS (
    SELECT 
        cd.c_name,
        SUM(cj.net_price) AS total_net_value,
        RANK() OVER (ORDER BY SUM(cj.net_price) DESC) AS total_rank
    FROM 
        CustomerDetails cd
    JOIN 
        ComplexJoin cj ON cd.order_count > 5
    GROUP BY 
        cd.c_name
)

SELECT 
    fr.c_name,
    fr.total_net_value,
    CASE 
        WHEN fr.total_net_value IS NULL THEN 'No Data'
        WHEN fr.total_rank = 1 THEN 'Top Customer'
        ELSE 'Other'
    END AS customer_tier
FROM 
    FinalResults fr
WHERE 
    fr.total_net_value > (SELECT AVG(total_net_value) FROM FinalResults)
ORDER BY 
    fr.total_net_value DESC;
