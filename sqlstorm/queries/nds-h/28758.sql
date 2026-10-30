WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
), 
NationSupplier AS (
    SELECT 
        n.n_name AS nation_name,
        s.s_name AS supplier_name,
        s.s_acctbal,
        s.s_comment
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
), 
CustomerOrders AS (
    SELECT 
        c.c_name AS customer_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_name
)
SELECT 
    rp.p_name,
    rp.p_mfgr,
    rp.p_brand,
    rp.p_type,
    ns.nation_name,
    ns.supplier_name,
    co.customer_name,
    co.total_orders,
    co.total_spent
FROM RankedParts rp
JOIN partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN NationSupplier ns ON s.s_name = ns.supplier_name
JOIN CustomerOrders co ON ns.supplier_name LIKE '%' || co.customer_name || '%'
WHERE rp.rank <= 5
ORDER BY rp.p_retailprice DESC, co.total_spent DESC;
