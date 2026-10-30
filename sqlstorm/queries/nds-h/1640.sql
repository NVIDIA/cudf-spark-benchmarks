WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        o.o_clerk,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' 
        AND o.o_orderdate < DATE '1997-01-01'
),
SupplierStats AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(*) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        COALESCE(s.total_supply_value, 0) AS total_supply_value,
        COALESCE(s.supplier_count, 0) AS supplier_count
    FROM 
        part p
    LEFT JOIN 
        SupplierStats s ON p.p_partkey = s.ps_partkey
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    r.o_orderstatus,
    pd.p_name,
    cs.c_name,
    pd.total_supply_value,
    cs.total_spent,
    (CASE 
        WHEN cs.total_spent IS NULL THEN 'No Orders' 
        ELSE 'Orders Exist' 
    END) AS order_status_info
FROM 
    RankedOrders r
JOIN 
    lineitem l ON r.o_orderkey = l.l_orderkey
JOIN 
    PartDetails pd ON l.l_partkey = pd.p_partkey
JOIN 
    CustomerSummary cs ON r.o_orderkey = cs.order_count
WHERE 
    pd.supplier_count > 0
    AND r.order_rank <= 10
ORDER BY 
    r.o_orderdate DESC, r.o_totalprice DESC;