
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost > 
            (SELECT AVG(pss.ps_supplycost) FROM partsupp pss WHERE pss.ps_availqty > 0))
),

SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'No Account Balance'
            ELSE CAST(s.s_acctbal AS VARCHAR(20))
        END AS acct_balance,
        r.r_name AS region_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        r.r_comment NOT LIKE '%obscure%'
),

TotalOrders AS (
    SELECT 
        o.o_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        SUM(CASE WHEN o.o_orderstatus = 'F' THEN 1 ELSE 0 END) AS fulfilled_orders
    FROM 
        orders o
    GROUP BY 
        o.o_custkey
),

CustomerRanking AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(o.order_count, 0) AS order_count,
        DENSE_RANK() OVER (ORDER BY COALESCE(o.total_spent, 0) DESC) AS customer_rank
    FROM 
        customer c
    LEFT JOIN 
        TotalOrders o ON c.c_custkey = o.o_custkey
)

SELECT 
    cr.c_name AS customer_name,
    sp.s_name AS supplier_name,
    rp.p_name AS part_name,
    rp.p_retailprice AS retail_price,
    cr.customer_rank,
    sd.acct_balance AS supplier_balance_status
FROM 
    CustomerRanking cr
JOIN 
    orders o ON cr.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier sp ON ps.ps_suppkey = sp.s_suppkey
JOIN 
    RankedParts rp ON rp.p_partkey = ps.ps_partkey
LEFT JOIN 
    SupplierDetails sd ON sp.s_suppkey = sd.s_suppkey
WHERE 
    rp.rn = 1
    AND cr.order_count > 5
    AND (sp.s_acctbal IS NOT NULL OR cr.order_count > 10)
ORDER BY 
    cr.customer_rank ASC, 
    rp.p_retailprice DESC;
