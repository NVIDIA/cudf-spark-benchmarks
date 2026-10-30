WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_retailprice > (
            SELECT AVG(p1.p_retailprice) 
            FROM part p1 
            WHERE p1.p_size BETWEEN 10 AND 20
        )
), 
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name,
        s.s_acctbal,
        COUNT(DISTINCT ps.ps_partkey) AS supply_count
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, s.s_acctbal
    HAVING 
        COUNT(DISTINCT ps.ps_partkey) > 5
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT CASE WHEN l.l_returnflag = 'R' THEN o.o_orderkey END) AS return_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
)

SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_retailprice,
    sd.s_name AS supplier_name,
    COALESCE(ao.order_count, 0) AS total_orders,
    COALESCE(ao.total_spent, 0) AS total_spent,
    CASE 
        WHEN ao.return_count > 0 THEN 'Contains Returns'
        ELSE 'No Returns' 
    END AS return_status
FROM 
    RankedParts rp
LEFT JOIN 
    SupplierDetails sd ON sd.supply_count > 3
LEFT JOIN 
    CustomerOrders ao ON ao.order_count > 10
WHERE 
    rp.rn <= 3
    AND rp.p_retailprice < (SELECT AVG(p2.p_retailprice) FROM part p2)
ORDER BY 
    rp.p_retailprice ASC, 
    sd.s_name DESC
LIMIT 100;
