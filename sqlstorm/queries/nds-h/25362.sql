WITH PartDetails AS (
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
        COALESCE(SUM(ps.ps_availqty), 0) AS total_avail_qty,
        COALESCE(SUM(ps.ps_supplycost), 0) AS total_supply_cost
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, p.p_container, p.p_retailprice, p.p_comment
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
    ORDER BY 
        total_supply_cost DESC
    LIMIT 10
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_custkey,
        c.c_name,
        c.c_mktsegment
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= '1997-01-01'
)
SELECT 
    pd.p_name,
    pd.p_brand,
    pd.p_retailprice,
    ts.s_name AS supplier_name,
    co.c_name AS customer_name,
    co.o_orderdate,
    co.o_totalprice,
    (CASE 
        WHEN pd.total_avail_qty >= 100 THEN 'High Availability'
        WHEN pd.total_avail_qty BETWEEN 50 AND 99 THEN 'Moderate Availability'
        ELSE 'Low Availability'
    END) AS availability_status
FROM 
    PartDetails pd
JOIN 
    TopSuppliers ts ON pd.p_partkey = ts.s_nationkey
JOIN 
    CustomerOrders co ON co.o_orderkey = pd.p_partkey
ORDER BY 
    pd.p_retailprice DESC, 
    co.o_totalprice DESC;