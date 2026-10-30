WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        ps.ps_availqty, 
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
),
SupplierNation AS (
    SELECT 
        s.s_suppkey, 
        n.n_name AS supplier_nation, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, n.n_name
),
OutstandingOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    rp.p_name, 
    rp.p_retailprice, 
    sn.supplier_nation, 
    oo.total_price, 
    COUNT(oo.o_orderkey) AS order_count
FROM 
    RankedParts rp
JOIN 
    SupplierNation sn ON rp.p_partkey = sn.s_suppkey
JOIN 
    OutstandingOrders oo ON rp.p_partkey = oo.o_orderkey
WHERE 
    rp.rank <= 10
GROUP BY 
    rp.p_name, rp.p_retailprice, sn.supplier_nation, oo.total_price
ORDER BY 
    total_price DESC, rp.p_retailprice ASC;
