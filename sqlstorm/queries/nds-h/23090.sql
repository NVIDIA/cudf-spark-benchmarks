WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_desc,
        COUNT(ps.ps_availqty) OVER (PARTITION BY p.p_partkey) AS available_suppliers
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_size IN (SELECT DISTINCT CASE 
                                          WHEN MOD(p2.p_partkey, 2) = 0 THEN p2.p_size 
                                          ELSE NULL END
                        FROM part p2)
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        (SELECT MAX(l.l_discount) FROM lineitem l WHERE l.l_orderkey = o.o_orderkey AND l.l_returnflag = 'N') AS max_discount
    FROM orders o
    WHERE o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderstatus = 'O')
),
SupplierCredit AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        CASE 
            WHEN SUM(s.s_acctbal) IS NULL THEN 'No Balance' 
            ELSE 'Balance Available' 
            END AS credit_status
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT 
    fp.p_name,
    fp.p_brand,
    fo.o_orderkey,
    fo.o_totalprice,
    fo.max_discount,
    sc.total_supply_cost,
    sc.credit_status
FROM RankedParts fp
JOIN FilteredOrders fo ON fo.o_totalprice < (SELECT AVG(l.l_extendedprice) FROM lineitem l WHERE l.l_returnflag = 'N')
FULL OUTER JOIN SupplierCredit sc ON fp.available_suppliers = sc.s_suppkey
WHERE fp.rank_desc <= 5 AND sc.total_supply_cost IS NOT NULL
ORDER BY fp.p_retailprice DESC NULLS LAST, sc.total_supply_cost DESC;
