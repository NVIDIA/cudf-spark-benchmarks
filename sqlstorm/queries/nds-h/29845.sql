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
), FilteredSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        s.s_nationkey, 
        s.s_phone, 
        s.s_acctbal, 
        s.s_comment
    FROM supplier s
    WHERE s.s_acctbal > 50000
), CombinedData AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        c.c_name AS customer_name,
        o.o_orderkey,
        lp.l_partkey, 
        lp.l_quantity, 
        lp.l_discount,
        rp.p_name,
        rp.p_retailprice
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN lineitem lp ON o.o_orderkey = lp.l_orderkey
    JOIN partsupp ps ON lp.l_partkey = ps.ps_partkey
    JOIN RankedParts rp ON ps.ps_partkey = rp.p_partkey
    JOIN FilteredSuppliers fs ON ps.ps_suppkey = fs.s_suppkey
    WHERE rp.rank <= 5
)
SELECT 
    region_name, 
    nation_name, 
    customer_name,
    COUNT(DISTINCT o_orderkey) AS total_orders,
    SUM(l_quantity) AS total_quantity,
    AVG(p_retailprice) AS average_retail_price
FROM CombinedData
GROUP BY region_name, nation_name, customer_name
ORDER BY total_orders DESC, total_quantity DESC;
