WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_availqty) DESC) AS rank_within_brand
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        DENSE_RANK() OVER (ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'F'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        COUNT(ps.ps_partkey) AS part_count
    FROM 
        supplier s
    LEFT JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
)
SELECT 
    cp.c_name AS customer_name,
    cp.o_orderkey AS order_id,
    rp.p_name AS part_name,
    sd.nation_name AS supplier_nation,
    rp.total_available_quantity,
    sd.part_count,
    CASE 
        WHEN rp.total_available_quantity IS NULL THEN 'Unavailable'
        ELSE 'Available'
    END AS availability_status
FROM 
    CustomerOrders cp
LEFT JOIN 
    lineitem l ON cp.o_orderkey = l.l_orderkey
LEFT JOIN 
    RankedParts rp ON l.l_partkey = rp.p_partkey AND rp.rank_within_brand <= 5
LEFT JOIN 
    SupplierDetails sd ON l.l_suppkey = sd.s_suppkey
WHERE 
    cp.order_rank <= 10
ORDER BY 
    cp.o_orderkey, rp.p_name;
