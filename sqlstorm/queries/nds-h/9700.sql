WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice > 100.00
),
SupplierOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        s.s_name,
        s.s_nationkey,
        SUM(li.l_quantity) AS total_quantity
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    JOIN 
        partsupp ps ON li.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        o.o_orderkey, o.o_totalprice, s.s_name, s.s_nationkey
),
CustomerNationSummary AS (
    SELECT 
        c.c_nationkey,
        COUNT(DISTINCT c.c_custkey) AS cust_count,
        SUM(o.o_totalprice) AS total_sales
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
)
SELECT 
    rn.n_name AS nation,
    p.p_name AS part_name,
    sp.total_quantity,
    cs.cust_count,
    cs.total_sales
FROM 
    RankedParts p
JOIN 
    SupplierOrders sp ON p.p_partkey = sp.o_orderkey
JOIN 
    nation rn ON sp.s_nationkey = rn.n_nationkey
JOIN 
    CustomerNationSummary cs ON rn.n_nationkey = cs.c_nationkey
WHERE 
    p.price_rank <= 5
ORDER BY 
    cs.total_sales DESC, sp.total_quantity ASC;
