WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
), 
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        CASE 
            WHEN p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) THEN 'Expensive'
            ELSE 'Affordable'
        END AS price_category
    FROM 
        part p
    WHERE 
        p.p_container LIKE '%BOX%'
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        DENSE_RANK() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus IN ('O', 'F') AND o.o_totalprice IS NOT NULL
)
SELECT 
    n.n_name AS nation_name,
    SUM(COALESCE(HighValueParts.p_retailprice, 0)) AS total_value,
    COUNT(DISTINCT orders.o_orderkey) AS total_orders,
    AVG(CASE WHEN l.l_returnflag = 'R' THEN l.l_discount ELSE NULL END) AS average_return_discount,
    COUNT(DISTINCT RankedSuppliers.s_suppkey) AS supplier_count
FROM 
    nation n
LEFT JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    CustomerOrders orders ON orders.c_custkey = c.c_custkey
LEFT JOIN 
    lineitem l ON l.l_orderkey = orders.o_orderkey
LEFT JOIN 
    HighValueParts ON HighValueParts.p_partkey = l.l_partkey
LEFT JOIN 
    RankedSuppliers ON RankedSuppliers.s_suppkey = l.l_suppkey
WHERE 
    HighValueParts.price_category = 'Expensive'
GROUP BY 
    n.n_name
HAVING 
    SUM(COALESCE(HighValueParts.p_retailprice, 0)) > (SELECT AVG(p_retailprice) FROM part)
ORDER BY 
    supplier_count DESC, total_value DESC
LIMIT 10;
