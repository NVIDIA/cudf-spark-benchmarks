
WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spending,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
),
PartStats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_quantity) AS total_quantity,
        AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= '1997-01-01' 
    GROUP BY 
        p.p_partkey, p.p_name
),
Ranking AS (
    SELECT 
        cs.c_custkey,
        cs.c_name,
        cs.total_spending,
        RANK() OVER (ORDER BY cs.total_spending DESC) AS spending_rank
    FROM 
        CustomerSummary cs
)
SELECT 
    rd.r_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    AVG(sd.part_count) AS avg_parts_per_supplier,
    SUM(ps.total_quantity) AS total_parts_sold,
    SUM(ps.avg_price) AS total_avg_price
FROM 
    region rd
LEFT JOIN 
    nation n ON rd.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierDetails sd ON s.s_suppkey = sd.s_suppkey
LEFT JOIN 
    lineitem l ON s.s_suppkey = l.l_suppkey
LEFT JOIN 
    PartStats ps ON l.l_partkey = ps.p_partkey
LEFT JOIN 
    CustomerSummary c ON c.c_custkey IN (SELECT c_custkey FROM Ranking WHERE spending_rank <= 10)
WHERE 
    sd.part_count IS NOT NULL
GROUP BY 
    rd.r_name
ORDER BY 
    customer_count DESC;
